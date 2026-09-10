#!/usr/bin/env python3

"""Decrypt a PAM v2 vault and write its JSON plaintext to stdout."""

import argparse
import base64
import binascii
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
PASSWORD_ENV = "PAM_PASSWORD"


class PamDecodeError(Exception):
    """Raised when a PAM vault cannot be decoded."""


def derive_key(password: str, salt: bytes) -> bytes:
    """Derive the PAM v2 AES-256 key from a password and salt."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=KEY_LEN,
        salt=salt,
        iterations=ITERATIONS,
    )
    return kdf.derive(password.encode("utf-8"))


def get_password() -> str:
    """Read the PAM password from the environment or controlling terminal."""
    password = os.environ.get(PASSWORD_ENV)

    if password is not None:
        if not password:
            raise PamDecodeError(f"{PASSWORD_ENV} is empty")
        return password

    password = getpass.getpass("Password: ")
    if not password:
        raise PamDecodeError("empty password")

    return password


def decrypt_v2(text: str, password: str) -> str:
    """Decrypt a PAM v2 payload and return its JSON plaintext."""
    if not text.startswith(PREFIX):
        raise PamDecodeError("not a PAM v2 file: missing PAMv2: prefix")

    try:
        raw = base64.b64decode(text[len(PREFIX):], validate=True)
    except (binascii.Error, ValueError) as exc:
        raise PamDecodeError(f"invalid Base64 data: {exc}") from exc

    if len(raw) < SALT_LEN + IV_LEN + 16:
        raise PamDecodeError("encrypted payload is too short")

    salt = raw[:SALT_LEN]
    iv = raw[SALT_LEN:SALT_LEN + IV_LEN]
    ciphertext = raw[SALT_LEN + IV_LEN:]

    if len(ciphertext) % 16:
        raise PamDecodeError(
            "ciphertext length is not a multiple of the AES block size"
        )

    key = derive_key(password, salt)
    decryptor = Cipher(
        algorithms.AES(key),
        modes.CBC(iv),
    ).decryptor()
    padded = decryptor.update(ciphertext) + decryptor.finalize()

    try:
        unpadder = padding.PKCS7(128).unpadder()
        plaintext = unpadder.update(padded) + unpadder.finalize()
    except ValueError as exc:
        raise PamDecodeError(
            "decryption failed: wrong password or damaged file"
        ) from exc

    try:
        plaintext_text = plaintext.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise PamDecodeError(
            "decryption produced invalid UTF-8: "
            "wrong password or damaged file"
        ) from exc

    try:
        json.loads(plaintext_text)
    except json.JSONDecodeError as exc:
        raise PamDecodeError(
            "decryption did not produce valid JSON: "
            "wrong password or damaged file"
        ) from exc

    return plaintext_text


def read_vault(path: str) -> str:
    """Read a PAM ciphertext file as ASCII text."""
    try:
        with open(path, "r", encoding="ascii") as file_obj:
            return file_obj.read().strip()
    except OSError as exc:
        raise PamDecodeError(str(exc)) from exc
    except UnicodeDecodeError as exc:
        raise PamDecodeError("vault is not ASCII PAM ciphertext") from exc


def main() -> int:
    """Run the PAM vault decoder command-line interface."""
    parser = argparse.ArgumentParser(
        description="Decrypt a PAM v2 vault to JSON."
    )
    parser.add_argument("vault", help="PAM vault file")
    args = parser.parse_args()

    try:
        encrypted = read_vault(args.vault)
        password = get_password()
        plaintext = decrypt_v2(encrypted, password)
    except PamDecodeError as exc:
        print(f"pam_decode: {exc}", file=sys.stderr)
        return 1

    sys.stdout.write(plaintext)
    if not plaintext.endswith("\n"):
        sys.stdout.write("\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
