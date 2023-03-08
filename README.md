# pam-crypt
[![Release](https://img.shields.io/github/release/jlinoff/pam-crypt?style)](https://github.com/jlinoff/pam-crypt/releases)

Encrypt/decrypt PAM and other files from the command line

pam-crypt is a node JS tool that will encrypt or decrypt a PAM text
based database file or any other text file from the command line
using the same algorithm that is used by PAM (AES-256-CBC).

It can be used to analyze the contents of the PAM database using
custom tools to understand characteristics of the account data.
For example you could use it to determine how many times a password
or username is duplicated.

It can also be used to facilitate record transfers to and from PAM
when combined with a custom tool that translates between the formats.

You must have a recent version of nodejs installed to use it. It was
developed with node v19.7.0.

You must also have the `atob` and `password-prompt` npm packages
installed.

Here is a simple example that shows how to decrypt a PAM generated
file (`example.txt`) that was encrypted with the password `example`.

```bash
pam-crypt -d -P example -i example.txt | jq .
```

For more information install `pam-crypt` and run:
```bash
make help             # to see the make targets
./pam-decrypt --help  # to see the program help
```

## Install
This is how to install pam-crypt locally.
```bash
git clone https://github.com/jlinoff/pam-crypt.git $HOME/pam-crypt
cd pam-crypt
make
make install
```

## Uninstall
Do this to to uninstall pam-crypt.

```bash
cd $HOME/pam-crypt
make uninstall
rm -rf $HOME/pam-crypt
```

## Errata

Random `jq` analysis ideas.


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
