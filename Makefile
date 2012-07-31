LIB_DIR = ./lib
VOWS_OPTS += --cover-html
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
	@$(shell npm bin)/coffee -o $@ -bc $<

pages:
	make -C doc clean html

release: test pages
	git checkout gh-pages
	cp -R doc/_build/html/ ./
	git commit -a -m v$(npm_package_version)
	git checkout $(HEAD)
