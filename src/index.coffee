# The main module just re-exports the most commonly used pieces

# Dialects and engines for easier extension
exports.dialects = require './dialects'
exports.engines = require './engines'
exports.defaultEngine = exports.engines.fakeEngine

# Common pre-defined value nodes (e.g. IS_NULL, LEFT_OUTER)
nodes = require './nodes'
for name in nodes.CONST_NODES
  exports[name] = nodes[name]

for name in nodes.JOIN_TYPES
  exports[name] = nodes[name]

# Re-export all nodes
exports.nodes = nodes

# Each query with capitalization to satisfy all tastes
uc      = (str) -> str.toUpperCase()
ucfirst = (str) -> str[0].toUpperCase() + str.substring 1
for queryType in ['select', 'update', 'insert', 'delete']
  query = require "./queries/#{queryType}"
  for name in [queryType, uc(queryType), ucfirst(queryType)]
    exports[name] = query
