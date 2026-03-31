#!/usr/bin/env python3
# Read JSON on stdin: {"ciphertext": "<base64 from google_kms_secret_ciphertext>"}
# Write JSON: {"bq_bytes_literal": "b'\\x..\\x..'"} for DLP_KEY_CHAIN(arg2) in BigQuery views.
import base64
import json
import sys


def main() -> None:
    payload = json.load(sys.stdin)
    raw = base64.b64decode(payload["ciphertext"], validate=True)
    inner = "".join("\\x%02x" % b for b in raw)
    json.dump({"bq_bytes_literal": "b'" + inner + "'"}, sys.stdout)


if __name__ == "__main__":
    main()
