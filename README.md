# pam-crypt - tools to encrypt/decrypt PAM vaults from the command line
[![Release](https://img.shields.io/github/release/jlinoff/pam-crypt?style)](https://github.com/jlinoff/pam-crypt/releases)

`pam-crypt` is an old node JS tool that will encrypt or decrypt old PAM
vaults (PAMv1).

`pam_decode.py` is a newer python based tool that will decrypt a PAMv2 file.
For the most recent versions for PAM (v2.0 or later).

`pam_encode.py` is a newer python based tool that will encrypt a JSON file.
For the most recent versions for PAM (v2.0 or later).

These tools can be used to analyze the contents of the PAM vault using
custom tools from the command line to understand characteristics of the
account data and rewrite the vault.

For example you could use `pam_decode.py` and `pam_encode.py` to merge
to manually add a record in your favorite editor or build a merge pipeline
to add new records from a local flow.

Here is a simple example that shows how to decrypt a PAM generated
file (`example.txt`) that was saved with the password `example`.

```bash
# decrypt it - old style this will fail for PAMv2 files.
./pam-crypt -d -P example -i example.txt -o example.txt.dec
# view the result
cat example.txt.dec | jq .

# decrypt it - new style that works for PAMv2 files.
# You can also set the password in the PAM_PASSWORD environment
# variable for scripts.
pipenv run ./pam_decode.py example.txt >example.txt.dec
Password:
# view the result
cat example.txt.dec | jq .
```

For more information run:
```bash
git clone https://github.com/jlinoff/pam-crypt.git
cd pam-crypt
./pam-crypt --help   # to see the old program help
pipenv run ./pam_decode.py --help # to see the PAMv2 decode program help
pipenv run ./pam_encode.py --help # to see the PAMv2 encode program help
make help
```

## Usage Examples

These are some simple usage example that show to use these tools.

### Create an Encrypted Example File

This shows how to create an encrypted file that can be read by PAM
from a plaintext JSON file.

```bash
PAM_PASSWORD='example' ./pam_encode.py example.txt > example.enc.txt
```

### Report Passwords for Each Record

This simple report outputs the record title and the passsword for the example data.

```bash
% head -1 example1.txt| cut -c -16
PAMv2:BNG1ubM7G2
% PAM_PASSWORD='example1' ./pam_decode.py example1.txt | jq -S -r '.records[] | objects | . as $r | .fields[] | select(.name=="password") | "\($r.title) ::: \(.value)"' | column -t -s ':::'
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

### Diff two files using meld

This is quite useful when looking for differences.

```bash
meld <(PAM_PASSWORD=example1 ./pam_decode.py example1.txt) <(PAM_PASSWORD=example2 ./pam_decode.py example2.txt)
```
