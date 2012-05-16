fluidize = require '../fluid'

BaseQuery = require './base'
SelectQuery = require './select'
{Insert, Tuple} = require '../nodes'

module.exports = class InsertQuery extends BaseQuery
  ###
  Insert queries are much simpler than most query types: they cannot join
  multiple tables.
  ###

  addRows: (rows...) ->
    ### Add multiple rows of data to the insert statement. ###
    for row in rows
      @q.addRow row

  addRow: (row) ->
    ### Add a single row ###
    @addRows row

  from: (query) ->
    ### Insert from a select query. ###
    switch query.constructor
      when SelectQuery then @q.source = @q.nodes[2] = query.q
      when Select then @q.source = query
      else throw new Error "Can only insert from a SELECT"

fluidize InsertQuery, 'addRow', 'addRows', 'from'

InsertQuery.into = (tbl, fields, opts={}) ->
  if not fields and fields.length
    throw new Error "Column list is required when constructing an INSERT"
  opts.table = tbl
  iq = new InsertQuery Insert, opts
  # TODO this is gross
  iq.q.columns = iq.q.nodes[1] = new Tuple fields
  return iq
