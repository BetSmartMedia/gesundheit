#!/bin/sh
[[ -d lib-tmp ]] || mkdir lib-tmp
coffee -o lib-tmp/ -c src/ && 
rm -fr lib && 
node-jscoverage lib-tmp/ lib/ &&
vows test/*test* --spec --cover-html
