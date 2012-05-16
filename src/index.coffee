exports.dialects = require './dialects'
exports.engines = require './engines'
exports.defaultEngine = exports.engines.fakeEngine()

exports.nodes = require './nodes'

for name, node of exports.nodes.CONST_NODES
  exports[name] = exports.nodes.CONST_NODES[name]

for name, node of exports.nodes.JOIN_TYPES
  exports[name] = exports.nodes.JOIN_TYPES[name]

# Each query with capitalization to satisfy all tastes
uc      = (str) -> str.toUpperCase()
ucfirst = (str) -> str[0].toUpperCase() + str.substring 1
for queryType in ['select', 'update', 'insert', 'delete']
  query = require "./queries/#{queryType}"
  for name in [queryType, uc(queryType), ucfirst(queryType)]
    exports[name] = query
