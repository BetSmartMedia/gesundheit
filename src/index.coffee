# The main entry point into gesundheit. Exports the most commonly used pieces directly.

# Export dialects for easier extension and/or changing of the default
exports.dialects = require './dialects'

common = require './dialects/common'
exports.DEFAULT  = common.DEFAULT
exports.NOT_NULL = common.NOT_NULL
exports.NULL     = common.NULL

# Monkey patch, so sue me
#   Better lawyer up: http://imgur.com/Qv8kt
String.prototype.ucfirst = -> this[0].toUpperCase() + this[1..-1]

# Export each query type, with capitalization to please the tastes of most everybody
for queryType in ['select', 'update', 'insert', 'delete']
	query = require "./#{queryType}"
	exports[queryType] = exports[queryType.toUpperCase()] = exports[queryType.ucfirst()] = query
