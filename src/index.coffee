exports.dialects = require './dialects'
exports.JOIN_TYPES = exports.dialects.JOIN_TYPES

# Monkey patch, so sue me
String.prototype.ucfirst = -> this[0].toUpperCase() + this[1..-1]

for queryType in ['select']
	query = require "./#{queryType}"
	exports[queryType] = exports[queryType.toUpperCase()] = exports[queryType.ucfirst()] = query
