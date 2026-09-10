#!/usr/bin/env python3

"""Encrypt JSON as a PAM v2 vault."""

import argparse
import base64
import getpass
import json
import os
import sys

from cryptography.hazmat.primitives import hashes, padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


PREFIX = "PAMv2:"
SALT_LEN = 16
IV_LEN = 16
KEY_LEN = 32
ITERATIONS = 600_000


class PamEncodeError(Exception):
    """Raised when JSON cannot be encoded as a PAM vault."""


def derive_key(password: str, salt: bytes) -> bytes:
    """Derive the PAM v2 AES-256 key from a password and salt."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=KEY_LEN,
        salt=salt,
        iterations=ITERATIONS,
    )
    return kdf.derive(password.encode("utf-8"))


def encrypt_v2(text: str, password: str) -> str:
    """Encrypt JSON plaintext using the PAM v2 format."""
    salt = os.urandom(SALT_LEN)
    iv = os.urandom(IV_LEN)
    key = derive_key(password, salt)

    padder = padding.PKCS7(128).padder()
    padded = padder.update(text.encode("utf-8")) + padder.finalize()

    encryptor = Cipher(
        algorithms.AES(key),
        modes.CBC(iv),
    ).encryptor()

    ciphertext = encryptor.update(padded) + encryptor.finalize()
    payload = salt + iv + ciphertext

    return PREFIX + base64.b64encode(payload).decode("ascii")


def read_json(path: str) -> str:
    """Read and validate a JSON document."""
    try:
        with open(path, "r", encoding="utf-8") as file_obj:
            text = file_obj.read()
    except OSError as exc:
        raise PamEncodeError(str(exc)) from exc

    try:
        json.loads(text)
    except json.JSONDecodeError as exc:
        raise PamEncodeError(f"invalid JSON: {exc}") from exc

    return text


def main() -> int:
    """Run the PAM vault encoder command-line interface."""
    parser = argparse.ArgumentParser(
        description="Encrypt JSON as a PAM v2 vault."
    )
    parser.add_argument("json_file", help="JSON file to encrypt")
    args = parser.parse_args()

    try:
        plaintext = read_json(args.json_file)
    except PamEncodeError as exc:
        print(f"pam_encode: {exc}", file=sys.stderr)
        return 1

    password = getpass.getpass("Password: ")
    if not password:
        print("pam_encode: empty password", file=sys.stderr)
        return 1

    confirmation = getpass.getpass("Confirm password: ")
    if password != confirmation:
        print("pam_encode: passwords do not match", file=sys.stderr)
        return 1

    encrypted = encrypt_v2(plaintext, password)
    sys.stdout.write(encrypted)
    sys.stdout.write("\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
