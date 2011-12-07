# The main module just re-exports the most commonly used pieces

# Dialects for easier extension and/or changing of the default
exports.dialects = require './dialects'

# Common pre-defined value nodes (e.g. IS_NULL, LEFT_OUTER)
nodes = require './nodes'
for name in nodes.CONST_NODES
  exports[name] = nodes[name]

for name in nodes.JOIN_TYPES
  exports[name] = nodes[name]

# Each query with capitalization to satisfy all tastes
uc      = (str) -> str.toUpperCase()
ucfirst = (str) -> str[0].toUpperCase() + str.substring 1
for queryType in ['select', 'update', 'insert', 'delete']
  query = require "./queries/#{queryType}"
  for name in [queryType, uc(queryType), ucfirst(queryType)]
    exports[name] = query
