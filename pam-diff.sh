#!/usr/bin/env bash
#
# Compare two PAM vaults.
#
# Usage:
#   pam-diff.sh file1 file2
#   DIFFTOOL=meld pam-diff.sh pam-file1 pam-file2
#   PAM_DECODE="./pam_decode.py" DIFFTOOL=meld pam-diff.sh pam-file1 pam-file2
#
# Decrypted content is written only to a private temporary directory, never
# beside the vault being compared, and that directory is removed on any exit.
#
# The earlier version wrote the decrypted JSON to "$PAM1.$$" — that is, into
# whatever directory the vault lives in, which for most people is a sync folder.
# It deleted the file afterwards, but only on the success path: an interrupt, a
# failing diff tool, or a crash left a complete plaintext copy of the vault
# sitting next to the encrypted one, where Dropbox or Spotlight would find it
# before the user did.
set -euo pipefail

DIFFTOOL="${DIFFTOOL:-diff}"
PAM_DECODE="${PAM_DECODE:-./pam_decode.py}"

if ! command -v "$DIFFTOOL" >/dev/null 2>&1 ; then
    echo "ERROR: tool not found: $DIFFTOOL" >&2
    exit 1
fi
if ! "$PAM_DECODE" --help >/dev/null 2>&1 ; then
    echo "ERROR: tool not found or not runnable: $PAM_DECODE" >&2
    exit 1
fi
if ! command -v jq >/dev/null 2>&1 ; then
    echo "ERROR: jq is required to normalise the JSON before comparing" >&2
    exit 1
fi

if [ $# -ne 2 ] ; then
    echo "ERROR: need exactly two files to compare." >&2
    echo "usage: $(basename "$0") file1 file2" >&2
    exit 1
fi

PAM1="$1"
PAM2="$2"

for f in "$PAM1" "$PAM2" ; do
    if [ ! -f "$f" ] ; then
        echo "ERROR: PAM file does not exist: $f" >&2
        exit 1
    fi
done

# A private directory, removed on ANY exit: success, failure, or signal.
# mktemp -d creates it 0700, so other users on the machine cannot read it.
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/pam-diff.XXXXXXXX")"


# Shellcheck gives a false warning here because it does not recognize
# the use in the trap statement.
# shellcheck disable=SC2329
cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM HUP

# Decrypt only if the file is not already plaintext JSON.
#
# An unencrypted vault starts with '{' — PAM writes one when saved with an
# empty password. An encrypted v2 vault starts with "PAMv2:".
prepare() {
    local src="$1" out="$2"
    # Report failures explicitly. Under `set -e` a failing jq or decode would
    # otherwise abort the script with no output at all, which looks identical
    # to a diff that found nothing.
    if head -c 1 "$src" | grep -q '{' ; then
        if ! jq -S . "$src" > "$out" ; then
            echo "ERROR: $src is not valid JSON" >&2
            exit 1
        fi
    else
        if ! "$PAM_DECODE" "$src" | jq -S . > "$out" ; then
            echo "ERROR: could not decrypt or parse $src" >&2
            echo "       wrong password, or not a PAM file?" >&2
            exit 1
        fi
    fi
}

prepare "$PAM1" "$WORKDIR/a.json"
prepare "$PAM2" "$WORKDIR/b.json"

echo "================================================================"
echo "DIFFTOOL : $DIFFTOOL"
echo "FILE 1   : $PAM1"
echo "FILE 2   : $PAM2"
echo "================================================================"

# `diff` exits 1 when the files differ, which is not an error here. Report the
# difference and return 0; anything above 1 is a real failure.
status=0
case "$DIFFTOOL" in
    diff)
        "$DIFFTOOL" -u "$WORKDIR/a.json" "$WORKDIR/b.json" || status=$?
        ;;
    *)
        "$DIFFTOOL" "$WORKDIR/a.json" "$WORKDIR/b.json" || status=$?
        ;;
esac

if [ "$status" -gt 1 ] ; then
    echo "ERROR: $DIFFTOOL failed with status $status" >&2
    exit "$status"
fi
exit 0
