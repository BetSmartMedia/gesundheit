LIB_DIR = ./lib
SRC_DIR = ./src
UNIT_TESTS ?= ./test/unit/
INTEGRATION_TESTS ?= ./test/integration/*.test.coffee
PATH := $(shell npm bin):$(PATH)
HEAD = $(shell git describe --contains --all HEAD)

.PHONY: all
all: $(LIB_DIR)

.PHONY: test
test: unit integration

.PHONY: unit
unit: $(LIB_DIR)
	@node_modules/.bin/tap test/unit/

.PHONY: integration
integration: $(LIB_DIR)
	@node_modules/.bin/tap test/integration/

.PHONY: clean
clean:
	rm -rf $(LIB_DIR)
	rm -rf lib-tmp

$(LIB_DIR): $(SRC_DIR)
	@node_modules/.bin/coffee -o $@ -bc $<

pages:
	make -C doc clean html

release: clean test pages
	git checkout gh-pages
	cp -R doc/_build/html/ ./
	[[ -z `git status -suno` ]] || git commit -a -m v$(npm_package_version)
	git checkout $(HEAD)
