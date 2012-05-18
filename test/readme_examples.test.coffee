sys = require 'sys'
vows = require 'vows'
assert = require 'assert'
fs = require 'fs'
coffee = require 'coffee-script'

# Hacky little test to make sure the examples in the readme run
vows.describe("README test").addBatch(
  "When the README has examples":
    topic: ->
      readme = fs.readFileSync(__dirname+'/../README.rst', 'utf-8')

      code = []
      issource = false
      lines = readme.split '\n'
      for line in readme.split '\n'
        code.push(line.replace(/^    /, '')) if line.match /^    /
      code[0] = code[0].replace './', '../'
      code.pop() # Remove npm install line
      code.join '\n'

    "the examples run": (code) ->
      eval code

).export(module)

