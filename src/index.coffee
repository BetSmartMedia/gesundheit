# The main entry point into gesundheit. Exports the most commonly used pieces directly.

# Export dialects for easier extension and/or changing of the default
exports.dialects = require './dialects'
exports.DEFAULT = require('./dialects/common').DEFAULT

# Monkey patch, so sue me
String.prototype.ucfirst = -> this[0].toUpperCase() + this[1..-1]

# Export each query type, with capitalization to please the tastes of most everybody
for queryType in ['select', 'insert', 'delete'] # , update
	query = require "./#{queryType}"
	exports[queryType] = exports[queryType.toUpperCase()] = exports[queryType.ucfirst()] = query
