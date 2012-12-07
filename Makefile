LIB_DIR = ./lib
SRC_DIR = ./src
UNIT_TESTS ?= ./test/unit/
INTEGRATION_TESTS ?= ./test/integration/*.test.coffee
PATH := $(shell npm bin):$(PATH)
HEAD = $(shell git describe --contains --all HEAD)

.PHONY: all
all: $(LIB_DIR)
	@cp $(SRC_DIR)/sql_keywords.txt $(LIB_DIR)/

.PHONY: test
test: unit integration

.PHONY: unit
unit: all
	@node_modules/.bin/tap test/unit/

.PHONY: integration
integration: $(LIB_DIR)
	@mysql -u root -e 'drop database gesundheit_test'
	@mysql -u root -e 'create database gesundheit_test'
	@psql -U postgres -c 'drop database gesundheit_test' 2>&1 >/dev/null
	@psql -U postgres -c 'create database gesundheit_test' 2>&1 >/dev/null
	@node_modules/.bin/tap test/integration/

.PHONY: clean
clean:
	@rm -rf $(LIB_DIR)
	@rm -rf lib-tmp

$(LIB_DIR): $(SRC_DIR)
	@node_modules/.bin/coffee -o $@ -bc $<

pages:
	make -C doc clean html

release: clean test pages
	git checkout gh-pages
	cp -R doc/_build/html/ ./
	[[ -z `git status -suno` ]] || git commit -a -m v$(npm_package_version)
	git checkout $(HEAD)
