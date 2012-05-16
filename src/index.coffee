exports.dialects = require './dialects'
exports.engines = require './engines'
exports.defaultEngine = exports.engines.fakeEngine()

exports.nodes = require './nodes'

for name, node of exports.nodes.CONST_NODES
  exports[name] = exports.nodes.CONST_NODES[name]

for name, node of exports.nodes.JOIN_TYPES
  exports[name] = exports.nodes.JOIN_TYPES[name]

exports[k] = v for k, v of require('./queries')
