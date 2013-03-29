returnable  = require './returnable'

BaseQuery   = require './base'
SelectQuery = require './select'
{Insert, toField} = require '../nodes'

module.exports = class InsertQuery extends BaseQuery
  ###
  Insert queries are much simpler than most query types: they cannot join
  multiple tables.
  ###
  @rootNode = Insert

  returnable @

  addRows: (rows, variadic) ->
    ### Add multiple rows of data to the insert statement. ###
    if variadic?
      console.warn("DEPRECATED: InsertQuery::addRows will not be variadic in a future release.")
      rows = Array::slice.call(arguments)
    for row in rows
      @q.addRow row

  addRow: (row) ->
    ### Add a single row ###
    @q.addRow row

  from: (query) ->
    ### Insert from a select query. ###
    @q.from(query.q or query)

fluid = require '../decorators/fluid'

InsertQuery::[method] = fluid(InsertQuery::[method]) for method in [
  'addRow', 'addRows', 'from', 'returning'
]
