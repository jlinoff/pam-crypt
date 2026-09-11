# pam-crypt — encrypt and decrypt PAM vaults from the command line

[![Release](https://img.shields.io/github/release/jlinoff/pam-crypt?style)](https://github.com/jlinoff/pam-crypt/releases)

Command-line tools for [PAM](https://github.com/jlinoff/pam) vault files. They
let you read, rewrite and compare vaults with ordinary Unix tools — `jq`,
`diff`, `meld`, an editor, a shell pipeline — rather than through the browser.

They also demonstrate something worth knowing about PAM: the file format is
AES-256-CBC and nothing proprietary. Your data is not locked inside the
application.

> ## ⚠ These tools decrypt your passwords
>
> Everything below produces **plaintext copies of your entire vault**. Every
> password, in the clear, in a terminal or a file.
>
> - **Prefer pipes to files.** `meld <(pam_decode.py a) <(pam_decode.py b)`
>   never writes plaintext to disk. `pam_decode.py a > a.json` does, and that
>   file will be picked up by backups, sync folders and desktop search.
> - **Delete any plaintext file when you are done**, and remember that deleting
>   does not remove it from a backup that has already run.
> - **Do not put the password on the command line.** See
>   [Passwords and shell history](#passwords-and-shell-history).
> - **Do not do this on a machine you do not control.**

## Requirements

| | For | Notes |
|---|---|---|
| Python 3.14 | `pam_decode.py`, `pam_encode.py` | the version pinned in `Pipfile` |
| `pipenv` | both Python tools | `pip install pipenv`, then `pipenv sync` |
| `jq` | the examples and `pam-diff.sh` | |
| Node.js | `pam-crypt` | only needed for PAMv1 files |

```bash
git clone https://github.com/jlinoff/pam-crypt.git
cd pam-crypt
pipenv sync          # install the Python dependencies
make help            # list the make targets
```

## Tools

| Tool | Format | Description |
|---|---|---|
| `pam_decode.py` | v2 | Decrypt a vault to JSON. |
| `pam_encode.py` | v2 | Encrypt JSON back into a vault. |
| `pam-diff.sh` | v2 | Compare two vaults, decrypting only into a private temporary directory. |
| `pam-crypt` | **v1 only** | The original Node tool. Superseded — see below. |

**`pam-crypt` is for old files only.** PAM v1 predates April 2026 and used a
weaker key derivation. If you still have v1 vaults, the better move is to load
them in PAM and re-save them, which writes v2; then use the Python tools. The
Node tool is kept so that existing v1 files remain readable.

## Passwords and shell history

Both Python tools read the password from the `PAM_PASSWORD` environment
variable, and prompt on the terminal if it is not set.

**Prompting is the safe default.** Just run the tool:

```bash
pipenv run ./pam_decode.py vault.txt
Password:
```

`PAM_PASSWORD` exists for scripts, but writing it inline —
`PAM_PASSWORD='hunter2' ./pam_decode.py …` — puts your master password in
`~/.bash_history`, where it stays. If you need it in a script, read it into the
variable rather than typing it:

```bash
read -rsp 'Password: ' PAM_PASSWORD
export PAM_PASSWORD
pipenv run ./pam_decode.py vault.txt | jq .
unset PAM_PASSWORD
```

Or take it from a keychain, which never puts it on a command line at all:

```bash
# macOS
export PAM_PASSWORD="$(security find-generic-password -s pam-vault -w)"
```

## Usage

The repository includes `example.txt`, an encrypted vault whose password is
`example`. Every example below uses it.

### Decrypt a vault

```bash
pipenv run ./pam_decode.py example.txt | jq .
Password:
```

Piping to `jq` rather than redirecting to a file keeps the plaintext out of the
filesystem.

### Encrypt JSON back into a vault

```bash
read -rsp 'Password: ' PAM_PASSWORD ; export PAM_PASSWORD
pipenv run ./pam_encode.py plain.json > vault.txt
unset PAM_PASSWORD
```

### Report the password for every record

```bash
pipenv run ./pam_decode.py example.txt |
  jq -S -r '.records[] | objects | . as $r | .fields[]
            | select(.name=="password") | "\($r.title) ::: \(.value)"' |
  column -t -s ':::'
```

```
Amazon                           hr5Hn9pqm3u.VqMiALfdN-"
Email pbrain22@protonmail.com    rHfZ6bihw$g8ra$P4hHD
Facebook                         dOa#DirgJge67okTKtEzp.LSl
GitHub                           Aq7GdcOmYWVkyHEWEk6fBeJzm
Google                           NIJMeb8OfXEfshOG$db!
Instagram                        dOa#DirgJge67okTKtEzp.LSl
Netflix                          cGwJ$NPQ4SsI#haEsFRD
StackExchange (StackOverflow)    FpnzQcuq0nk/PxlMdYJ_itnK
Toys-R-Us                        wUq7!vTm2$eLxR9dNc4A
```

Facebook and Instagram share a password. That is deliberate in the example
data — it is what PAM's own reuse report is built to find.

### Find reused passwords

```bash
pipenv run ./pam_decode.py example.txt |
  jq -r '.records[] | . as $r | .fields[]
         | select(.name=="password") | "\(.value)\t\($r.title)"' |
  sort | uniq -D -f0 -w40
```

### Compare two vaults

`pam-diff.sh` handles the decryption, normalises both sides with `jq -S` so key
order does not show up as a difference, and keeps the plaintext in a private
temporary directory that is removed even if the diff tool is interrupted.

```bash
./pam-diff.sh old-vault.txt new-vault.txt            # unified diff
DIFFTOOL=meld ./pam-diff.sh old-vault.txt new-vault.txt   # side by side
```

It accepts plaintext JSON as well as encrypted vaults, so you can compare a
vault against an exported copy without re-encrypting first.

If you prefer to do it by hand, process substitution keeps the plaintext out of
the filesystem:

```bash
meld <(pipenv run ./pam_decode.py a.txt) <(pipenv run ./pam_decode.py b.txt)
```

### Edit a vault in place

Decrypt, edit, re-encrypt. This is the pipeline for bulk changes that the
browser cannot do — renaming a field across every record, say, or merging in
entries from elsewhere.

```bash
read -rsp 'Password: ' PAM_PASSWORD ; export PAM_PASSWORD

pipenv run ./pam_decode.py vault.txt > /tmp/vault.json   # plaintext on disk
"$EDITOR" /tmp/vault.json
pipenv run ./pam_encode.py /tmp/vault.json > vault-new.txt
shred -u /tmp/vault.json 2>/dev/null || rm -f /tmp/vault.json

unset PAM_PASSWORD
```

This is the one workflow that must write plaintext to disk. Put it under
`/tmp`, never in the directory holding the vault, and remove it immediately.

## Make targets

```bash
make help     # list the targets
make setup    # install the npm dependencies used by the v1 tool
make lint     # jshint on pam-crypt, pylint on the Python tools
make test     # round-trip v1 and v2: encrypt, decrypt, compare against the source
make all      # setup, lint, test
```

`make test` is a round-trip check: it encrypts `example.txt`, decrypts the
result, and diffs it against the original. If that passes, the tools are
mutually consistent and compatible with the format PAM writes.

## License

MIT. See [LICENSE](./LICENSE).
