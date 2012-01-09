sys = require 'sys'
vows = require 'vows'
assert = require 'assert'
fs = require 'fs'
coffee = require 'coffee-script'

# Hacky little test to make sure the examples in the readme run
vows.describe("README test").addBatch(
	"When the README has examples":
		topic: ->
			readme = fs.readFileSync(__dirname+'/../README.markdown', 'ascii')

			examples = []
			currentsource = ["{select} = require '../lib'"]
			issource = false
			for line in readme.split '\n'
				if line.match /```coffee/
					issource=true
				else if issource and line.match /```/
					issource=false
					examples.push currentsource.join '\n'
					currentsource = ["{select} = require '../lib'"]
				else if issource
					currentsource.push line

			return examples

		"and the examples compile":
			topic: (examples) -> coffee.compile e for e in examples

			"the examples run": (e) ->
				for example in e
					eval example

).export(module)

