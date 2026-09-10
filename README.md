# pam-crypt - tools to encrypt/decrypt PAM vaults from the command line
[![Release](https://img.shields.io/github/release/jlinoff/pam-crypt?style)](https://github.com/jlinoff/pam-crypt/releases)

`pam-crypt` is an old node JS tool that will encrypt or decrypt old PAM
vaults (PAMv1).

`pam_decode.py` is a newer python based to that will decrupt a PAMv2 file.
These are the most recent files handled by PAM.

Both can be used to analyze the contents of the PAM database using
custom tools to understand characteristics of the account data.
For example you could use it to determine how many times a password
or username is duplicated which is already handled in PAM by the
reuse menu function.

Here is a simple example that shows how to decrypt a PAM generated
file (`example.txt`) that was saved with the password `example`.

```bash
# decrypt it - old style this will fail for PAMv2 files.
./pam-crypt -d -P example -i example.txt -o example.txt.dec
# view the result
cat example.txt.dec | jq .

# decrypt it - new style this works for PAMv2 files.
pipenv run ./pam_decode.py example.txt >example.txt.dec
Password:
# view the result
cat example.txt.dec | jq .
```

For more information run:
```bash
git clone https://github.com/jlinoff/pam-crypt.git
cd pam-crypt
./pam-crypt --help   # to see the program help
./pam_decrypt --help # to see the program help
```

### Lint and test
```bash
make lint
make test
```

## Install
```bash
git clone https://github.com/jlinoff/pam-crypt.git
cd pam-crypt
make
make install
```

## Uninstall

```bash
make uninstall
```

## Errata

`jq` analysis ideas.


### various random ideas
```bash
./pam-crypt -d -P example -i mystuff.txt |\
    jq '.records[] | objects | .fields[] | "\(.name):, \(.value)"'

./pam-crypt -d -P example -i mystuff.txt |\
    jq '.records[] | objects | .fields[] | select(.type=="password") | "password: \(.value)"'

./pam-crypt -d -P example -i mystuff.txt |\
    jq '.records[] | objects | [.fields[] | select(.type=="password") | "password: \(.value)"]'

./pam-crypt -d -P example -i mystuff.txt |\
    jq '.records[] | objects | ["title: \(.title)", ( .fields[] | select(.type=="password") | "password: \(.value)")]'

./pam-crypt -d -P example -i mystuff.txt |\
    jq '.records[] | objects | [( .fields[] | select(.type=="password") | "password: \(.value)"), "title: \(.title)"]'  -c | \
    rg '^."password:.' | sort -f

./pam-crypt -d -P example -i mystuff.txt |\
    jq '.records[] | objects | [( .fields[] | select(.name=="password") | "p: \(.value)"), "  ::: \(.title)"]'  -c | rg '^."p:' | \
    sort -f | column -s ':::' -t
```

### table of passwords and titles
```
$ ./pam-crypt -d -P example -i example.txt | \
   jq '.records[] | objects | [( .fields[] | select(.name=="password") | "p: \(.value)"), "  ::: \(.title)"]'  -c | rg '^."p:' | \
   sort -f | column -s ':::' -t
```

# document how i created the favicon
