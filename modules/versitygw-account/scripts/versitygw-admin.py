#!/usr/bin/env python3
"""Converge one versitygw account or bucket through the gateway's admin API.

Terraform cannot sign SigV4 and the admin API accepts nothing else, so this is
driven from a `local-exec` provisioner. Standard library only.

Every operation converges rather than creates: the module never destroys a
bucket, so a re-added consumer arrives with its bucket already present, and a
non-idempotent create would fail every subsequent apply.

All inputs arrive as environment variables, never argv. Credentials would
otherwise have to sit in the resource's `input` and so in Terraform state; and
`local-exec` evaluates its command through /bin/sh, which would execute a bucket
name containing `;` before this program started.
"""
import datetime
import hashlib
import hmac
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ElementTree

SERVICE = "s3"


def env(name):
    value = os.environ.get(name)
    if not value:
        sys.exit("FAIL: %s is not set in the environment" % name)
    return value


ENDPOINT = env("VERSITYGW_ADMIN_ENDPOINT").rstrip("/")
ACCESS = env("VERSITYGW_ADMIN_ACCESS_KEY")
SECRET = env("VERSITYGW_ADMIN_SECRET_KEY")
REGION = os.environ.get("VERSITYGW_ADMIN_REGION", "us-east-1")


def _sign(key, msg):
    return hmac.new(key, msg.encode(), hashlib.sha256).digest()


def call(method, path, query=None, body=b"", extra_headers=None):
    """Issue one SigV4-signed request. Returns (status, body)."""
    query = query or {}
    extra_headers = extra_headers or {}
    host = urllib.parse.urlparse(ENDPOINT).netloc
    now = datetime.datetime.now(datetime.timezone.utc)
    amzdate = now.strftime("%Y%m%dT%H%M%SZ")
    datestamp = now.strftime("%Y%m%d")
    payload_hash = hashlib.sha256(body).hexdigest()

    canonical_query = "&".join(
        "%s=%s" % (urllib.parse.quote(k, safe="-_.~"), urllib.parse.quote(str(v), safe="-_.~"))
        for k, v in sorted(query.items())
    )
    headers = {"host": host, "x-amz-content-sha256": payload_hash, "x-amz-date": amzdate}
    headers.update({k.lower(): v for k, v in extra_headers.items()})
    canonical_headers = "".join("%s:%s\n" % (k, headers[k]) for k in sorted(headers))
    signed_headers = ";".join(sorted(headers))
    canonical_request = "\n".join(
        [method, path, canonical_query, canonical_headers, signed_headers, payload_hash]
    )

    scope = "%s/%s/%s/aws4_request" % (datestamp, REGION, SERVICE)
    to_sign = "\n".join(
        ["AWS4-HMAC-SHA256", amzdate, scope, hashlib.sha256(canonical_request.encode()).hexdigest()]
    )
    signing_key = _sign(("AWS4" + SECRET).encode(), datestamp)
    for part in (REGION, SERVICE, "aws4_request"):
        signing_key = _sign(signing_key, part)
    signature = hmac.new(signing_key, to_sign.encode(), hashlib.sha256).hexdigest()

    url = ENDPOINT + path + (("?" + canonical_query) if canonical_query else "")
    request = urllib.request.Request(url, data=body, method=method)
    request.add_header("X-Amz-Date", amzdate)
    request.add_header("X-Amz-Content-Sha256", payload_hash)
    request.add_header(
        "Authorization",
        "AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s"
        % (ACCESS, scope, signed_headers, signature),
    )
    for key, value in extra_headers.items():
        request.add_header(key, value)
    if body:
        request.add_header("Content-Type", "application/xml")

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, response.read().decode()
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def expect_ok(status, payload, what):
    if not 200 <= status < 300:
        sys.exit("FAIL: %s returned HTTP %d: %s" % (what, status, payload.strip()))
    return payload


def list_accounts():
    payload = expect_ok(*call("PATCH", "/list-users"), what="list-users")
    root = ElementTree.fromstring(payload)
    return {
        entry.findtext("Access"): entry.findtext("Role")
        for entry in root.iter("Accounts")
        if entry.findtext("Access")
    }


def bucket_owners():
    payload = expect_ok(*call("PATCH", "/list-buckets"), what="list-buckets")
    root = ElementTree.fromstring(payload)
    return {
        entry.findtext("Name"): entry.findtext("Owner")
        for entry in root.iter("Buckets")
        if entry.findtext("Name")
    }


def converge_account(access, secret, role):
    """Create the account, or bring an existing one back to the declared state."""
    body = (
        "<Account><Access>%s</Access><Secret>%s</Secret><Role>%s</Role>"
        "<UserID>0</UserID><GroupID>0</GroupID></Account>" % (access, secret, role)
    ).encode()
    if access in list_accounts():
        # Convergent, so safe every apply; this is also what repairs a rotated secret.
        expect_ok(*call("PATCH", "/update-user", query={"access": access}, body=body),
                  what="update-user %s" % access)
        print("account %s converged (role %s)" % (access, role))
        return
    expect_ok(*call("PATCH", "/create-user", body=body), what="create-user %s" % access)
    print("account %s created (role %s)" % (access, role))


def converge_bucket(bucket, owner):
    """Create the bucket owned by `owner`, or correct its owner if it exists.

    change-bucket-owner discards the bucket's ACL and policy, so it is issued only
    when the observed owner actually differs.
    """
    observed = bucket_owners().get(bucket)
    if observed is None:
        status, payload = call("PATCH", "/%s/create" % bucket, extra_headers={"X-Vgw-Owner": owner})
        # The bucket can exist without this module having created it.
        if status == 409 and "AlreadyOwnedByYou" in payload:
            print("bucket %s already exists, treating as converged" % bucket)
        else:
            expect_ok(status, payload, what="create-bucket %s" % bucket)
            print("bucket %s created, owned by %s" % (bucket, owner))
        observed = bucket_owners().get(bucket)
    if observed == owner:
        print("bucket %s owned by %s" % (bucket, owner))
        return
    expect_ok(
        *call("PATCH", "/change-bucket-owner/", query={"bucket": bucket, "owner": owner}),
        what="change-bucket-owner %s" % bucket,
    )
    print("bucket %s owner corrected from %s to %s" % (bucket, observed, owner))


def delete_account(access):
    """Remove an account. Absent is the desired end state, so absent is success."""
    if access not in list_accounts():
        print("account %s already absent" % access)
        return
    expect_ok(*call("PATCH", "/delete-user", query={"access": access}), what="delete-user %s" % access)
    print("account %s deleted" % access)


# Shape validation, not a shell guard: the admin CLI reports accounts in a
# whitespace-delimited table keyed on the access key, and carries bucket and owner
# in a URL query string.
IDENTIFIER = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def checked(value, what):
    if not IDENTIFIER.match(value or ""):
        sys.exit("FAIL: %s %r is not a plain identifier" % (what, value))
    return value


def checked_env(name, what):
    return checked(env(name), what)


def main(argv):
    if len(argv) < 2:
        sys.exit("usage: versitygw-admin.py {converge-account|converge-bucket|delete-account}")
    operation = argv[1]
    if operation == "converge-account":
        converge_account(
            checked_env("VERSITYGW_ACCOUNT_ACCESS", "access key"),
            env("VERSITYGW_ACCOUNT_SECRET"),
            checked_env("VERSITYGW_ACCOUNT_ROLE", "role"),
        )
    elif operation == "converge-bucket":
        converge_bucket(
            checked_env("VERSITYGW_BUCKET", "bucket"),
            checked_env("VERSITYGW_BUCKET_OWNER", "owner"),
        )
    elif operation == "delete-account":
        delete_account(checked_env("VERSITYGW_ACCOUNT_ACCESS", "access key"))
    else:
        sys.exit("FAIL: unknown operation %s" % operation)


main(sys.argv)
