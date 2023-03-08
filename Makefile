TERM_ANSI_BOLD    := "\\033[1m"
TERM_ANSI_GREEN   := "\\033[32m"
TERM_ANSI_MAGENTA := "\\033[35m"
TERM_ANSI_RESET   := "\\033[0m"
TARGET := printf "${TERM_ANSI_BOLD}${TERM_ANSI_MAGENTA}\n=-=-=-=-= %s: %s =-=-=-=-=${TERM_ANSI_RESET}\n" "`date`"
PRINT  := printf "${TERM_ANSI_BOLD}${TERM_ANSI_MAGENTA}%s${TERM_ANSI_RESET}\n" "`date`"
INSTALL_DIR ?= /usr/local/bin

.PHONY: default
default: all  ## Default is "all".

.PHONY: all
all: lint test  ## Run the lint and test targets.

.PHONY: install
install: $(INSTALL_DIR)/pam-crypt  ## Install $(INSTALL_DIR)/pam-crypt.

$(INSTALL_DIR)/pam-crypt: pam-crypt
	sudo cp pam-crypt $@

.PHONY: uninstall
uninstall:  ## Uninstall $(INSTALL_DIR)/pam-crypt.
	sudo rm -f $(INSTALL_DIR)/pam-crypt

.PHONY: setup
setup:  ## npm install atob and password-prompt
	@$(TARGET) $@
	node --version
	npm install atob
	npm install password-prompt

.PHONY: test
test: test1 test2 test3 test4 test5  ## Run all tests.

.PHONY: test1
test1: | example.txt  ## testbasic decryption.
	@$(TARGET) $@
	node --version
	./pam-crypt -d -P example -i example.txt > $@.js
	file $@.js
	@$(PRINT) "$@ PASSED"

.PHONY: test2
test2: | example.txt  ## Test -P and -o.
	@$(TARGET) $@
	@rm -rf $@*
	node --version
	echo -n 'example' >$@.pass
	./pam-crypt -d -p $@.pass -i example.txt -o $@.js
	file $@.js
	@$(PRINT) "$@ PASSED"

.PHONY: test3
test3: | README.md  ## Test encryption and decryption.
	@$(TARGET) $@
	@rm -rf $@*
	node --version
	./pam-crypt -e -P $@ -i README.md -o $@.enc
	file $@.enc
	./pam-crypt -d -P $@ -i $@.enc -o $@.dec
	diff README.md $@.dec
	@$(PRINT) "$@ PASSED"

# double enc/dec
.PHONY: test4
test4: | example.txt  ## Test double encryption and decryption.
	@$(TARGET) $@
	@rm -rf $@*
	node --version
	./pam-crypt -e -P example -i example.txt -o $@.enc.enc
	./pam-crypt -d -P example -i $@.enc.enc -o $@.dec.dec
	./pam-crypt -d -P example -i $@.dec.dec -o $@.dec
	file $@.dec
	@$(PRINT) "$@ PASSED"

# stdin
.PHONY: test5
test5: | example.text  ## Test read from stdin.
	@$(TARGET) $@
	@rm -rf $@*
	node --version
	echo -n 'example' >$@.pass
	cat example.txt | ./pam-crypt -d -p $@.pass -o $@.js
	file $@.js
	@$(PRINT) "$@ PASSED"

.PHONY: lint
lint:  ## Run jshint to lint the javascript.
	@$(TARGET) $@
	jshint --config jshint.json pam-crypt
	@echo "$@ PASSED"

.PHONY: help
help:
	@$(TARGET) $@
	@column --version
	@echo "make targets:"
	@grep -E '^\S+:.*##' $(MAKEFILE_LIST) | \
		sed -e 's/\([^ \t]*\).*##/\1 ##/' | \
		sort -f | \
		column -s '##' -t | sed -e 's/^/    /'
	@echo "make variables"
	@echo "INSTALL_DIR ## $(INSTALL_DIR)" | column -s '##' -t | sed -e 's/^/    /'
