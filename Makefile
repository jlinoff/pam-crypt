TERM_ANSI_BOLD    := "\\033[1m"
TERM_ANSI_GREEN   := "\\033[32m"
TERM_ANSI_MAGENTA := "\\033[35m"
TERM_ANSI_RESET   := "\\033[0m"
TARGET := printf "${TERM_ANSI_BOLD}${TERM_ANSI_MAGENTA}\n=-=-=-=-= %s: %s =-=-=-=-=${TERM_ANSI_RESET}\n" "`date`"
PRINT  := printf "${TERM_ANSI_BOLD}${TERM_ANSI_MAGENTA}%s${TERM_ANSI_RESET}\n" "`date`"

.PHONY: default
default: all

.PHONY: all
all: setup lint test  ## Default. Run the lint and test targets.

.PHONY: clean
clean:
	@$(TARGET) $@
	git clean -d -x -f -e keep

.PHONY: setup
setup:  ## npm install atob and password-prompt
	@$(TARGET) $@
	node --version
	npm install atob
	npm install password-prompt
	npm install -g jshint

.PHONY: test
test: test-pamv1 test-pamv2 ## Run tests.

.PHONY: test-pamv1
test-pamv1: | example.txt
	@$(TARGET) $@
	@rm -f $@.*
	node --version
	./pam-crypt -e -P example -i example.txt -o $@.enc.json
	./pam-crypt -d -P example -i $@.enc.json -o $@.dec.json
	file $@.enc.json
	file $@.dec.json
	jq -S . $@.dec.json > $@.dec.json.1
	jq -S . example.txt > $@.dec.json.2
	diff $@.dec.json.1 $@.dec.json.2
	@$(PRINT) "$@ - PASSED"
	@rm -f $@.*

.PHONY: test-pamv2
test-pamv2: | example.txt
	@$(TARGET) $@
	@rm -f $@.*
	PAM_PASSWORD="example" pipenv run ./pam_encode.py example.txt >$@.enc.json
	PAM_PASSWORD="example" pipenv run ./pam_decode.py $@.enc.json >$@.dec.json
	file $@.enc.json
	file $@.dec.json
	jq -S . $@.dec.json > $@.dec.json.1
	jq -S . example.txt > $@.dec.json.2
	diff $@.dec.json.1 $@.dec.json.2
	@$(PRINT) "$@ - PASSED"
	@rm -f $@.*

.PHONY: lint
lint:  ## Lint javascript, python and shellscripts.
	@$(TARGET) $@
	jshint --config jshint.json pam-crypt
	pipenv run pylint pam_decode.py
	pipenv run pylint pam_encode.py
	shellcheck webtest.sh
	@echo "$@ PASSED"

.PHONY: webtest
webtest:  ## Serve the pam-vault-diff.html web tool locally to diff vaults or copy records.
	./webtest.sh

.PHONY: zip
zip:  project.zip  ## Make the project.zip file from git repo contents.

GIT_SRC_FILES := $(shell git ls-files)
project.zip: $(GIT_SRC_FILES)
	zip "$@" $(GIT_SRC_FILES)

.PHONY: help
help:
	@$(TARGET) $@
	@echo "make targets:"
	@grep -E '^[^.[:space:]][^[:space:]]*:.*[[:space:]]##' $(MAKEFILE_LIST) 2>/dev/null | \
		grep -E -v '^ *#' | \
		grep -E -v "egrep|sort|sed|MAKEFILE" | \
		sed -e 's/:[[:space:]].*##/##/' -e 's/^[^:#]*://' | \
		awk -F'##' '{printf("%-18s %s\n",$$1,$$2)}' | \
		sort -f | \
		sed -e 's@^@   @'
