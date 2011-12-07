#!/bin/sh
ARGS="$@"
[[ -z "$@" ]] && ARGS='test/*test.coffee'
[[ -d lib-tmp ]] || mkdir lib-tmp
coffee -o lib-tmp/ -c src/ && 
cp src/fluid.js lib-tmp/
rm -fr lib && 
node-jscoverage lib-tmp/ lib/ &&
vows --debug-brk --cover-html $ARGS && 
rm -fr lib && mv lib-tmp/ lib/
