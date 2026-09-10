#!/usr/bin/env bash
#
# Usage:
#   pam-diff.sh file1 file2
#   DIFFTOOL=meld pam-diff.sh pam-file1 pam-file2
#   PAM_DECODE="./pam_decode.py" DIFFTOOL=meld pam-diff.sh pam-file1 pam-file2
if [ -z "$DIFFTOOL" ] ; then
    DIFFTOOL="diff"
fi
if [ -z "$PAM_DECODE" ] ; then
    PAM_DECODE="./pam_decode.py"
fi

if ! "$DIFFTOOL" --help >/dev/null ; then
    echo "ERROR: tool not found: $DIFFTOOL"
    exit 1
fi
if ! "$PAM_DECODE" --help > /dev/null ; then
    echo "ERROR: tool not found: $PAM_DECODE"
    exit 1
fi

# check argument existence
if [ -z "$1" ] ; then
    echo "ERROR: Files not specified."
    exit 1
fi

if [ -z "$2" ] ; then
    echo "ERROR: Need two files to compare."
    exit 1
fi

PAM1="$1"
PAM2="$2"

# check file existence
if [ ! -f "$PAM1" ] ; then
    echo "ERROR: PAM file does not exist: $PAM1"
    exit 1
fi

if [ ! -f "$PAM2" ] ; then
    echo "ERROR: PAM file does not exist: $PAM2"
    exit 1
fi

# check encryption
if ! head -4 "$PAM1"| cut -c -10 | grep '"meta"' ; then
    PAM1_DIFF="$PAM1.$$"
    rm -f "$PAM1_DIFF"
    echo "$PAM_DECODE $PAM1 > $PAM1_DIFF"
    if ! "$PAM_DECODE" "$PAM1" >"$PAM1_DIFF" ; then
        echo "ERROR: Command failed"
        exit 1
    fi
    PAM1_DELETE=1
else
    PAM1_DIFF="$PAM1"
    PAM1_DELETE=0
fi

if ! head -4 "$PAM2"| cut -c -10 | grep '"meta"' ; then
    PAM2_DIFF="$PAM2.$$"
    rm -f "$PAM2_DIFF"
    echo "$PAM_DECODE $PAM2 > $PAM2_DIFF"
    if ! "$PAM_DECODE" "$PAM2" >"$PAM2_DIFF" ; then
        echo "ERROR: Command failed"
        exit 1
    fi
    PAM2_DELETE=1
else
    PAM2_DIFF="$PAM2"
    PAM2_DELETE=0
fi

# diff em
echo "================================================================"
echo "DIFFTOOL : $DIFFTOOL"
echo "PAM1_DIFF: $PAM1_DIFF"
echo "PAM3_DIFF: $PAM2_DIFF"
echo "================================================================"
case "$DIFFTOOL" in
    diff)
        "$DIFFTOOL" -u <(jq -S . "$PAM1_DIFF") <(jq -S . "$PAM2_DIFF")
        ;;
    *)
        "$DIFFTOOL" <(jq -S . "$PAM1_DIFF") <(jq -S . "$PAM2_DIFF")
        ;;
esac
wait
if (( PAM1_DELETE )) ; then
    rm -f "$PAM1_DIFF"
fi
if (( PAM2_DELETE )) ; then
    rm -f "$PAM2_DIFF"
fi
