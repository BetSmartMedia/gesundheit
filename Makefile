LIB_DIR = ./lib
VOWS_OPTS += --debug-brk --cover-html
SRC_DIR = ./src
TEST ?= ./test/*.test.coffee

.PHONY: all
all: $(LIB_DIR)

.PHONY: test
test: $(LIB_DIR)
	vows $(VOWS_OPTS) $(TEST)

.PHONY: fulltest
fulltest: coverage
	vows $(VOWS_OPTS) $(TEST)

# TODO: put instrumented code somewhere other than ./lib
.PHONY: coverage
coverage: $(LIB_DIR)
	rm -rf lib-tmp
	mv $< lib-tmp
	node-jscoverage lib-tmp $<

.PHONY: clean
clean:
	rm -rf $(LIB_DIR)
	rm -rf lib-tmp

$(LIB_DIR): $(SRC_DIR)
	coffee -o $@ -c $<
