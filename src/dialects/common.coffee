uuid = require 'node-uuid'

exports.JOIN_TYPES = [
	'LEFT', 'RIGHT', 'INNER',
	'LEFT OUTER', 'RIGHT OUTER', 'FULL OUTER'
	'NATURAL', 'CROSS'
]

exports.DEFAULT  = uuid()
exports.NOT_NULL = uuid()
exports.NULL     = uuid()
