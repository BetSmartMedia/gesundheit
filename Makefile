LIB_DIR = ./lib
VOWS_OPTS += --cover-html
SRC_DIR = ./src
TEST ?= ./test/*/*.test.coffee
HEAD = $(shell git describe --contains --all HEAD)

.PHONY: all
all: $(LIB_DIR)

.PHONY: test
test: $(LIB_DIR)
	@vows $(VOWS_OPTS) $(TEST)

.PHONY: fulltest
fulltest: coverage
	@vows $(VOWS_OPTS) $(TEST)

.PHONY: coverage
coverage: $(LIB_DIR)
	@rm -rf lib-tmp
	@mv $< lib-tmp
	@node_modules/.bin/node-jscoverage lib-tmp $<

.PHONY: clean
clean:
	rm -rf $(LIB_DIR)
	rm -rf lib-tmp

$(LIB_DIR): $(SRC_DIR)
	@coffee -o $@ -c $<

pages:
	make -C doc clean html

release: test pages
	git checkout gh-pages
	cp -R doc/_build/html/ ./
	git commit -a -m v$(npm_package_version)
	git checkout $(HEAD)
