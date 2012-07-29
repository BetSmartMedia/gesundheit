###
The query manager classes use the following inheritance hierarchy:

  * BaseQuery

    * InsertQuery

    * SUDQuery

      * SelectQuery

      * UpdateQuery

      * DeleteQuery

The query factory functions defined here each accept an optional visitor
callback as a final parameter.  are re-exported by the main gesundheit modu
by the main gesundheit module:
###

{Tuple}     = require './../nodes'
InsertQuery = require './insert'
SelectQuery = require './select'
UpdateQuery = require './update'
DeleteQuery = require './delete'

exports.insert = (table, fields) ->
  ###
  Create a new :class:`queries/insert::InsertQuery` that will add rows to
  ``table``.

  :param fields: Either an array of column names that will be inserted, or a
    plain object representing a row of data to insert, in which case the keys
    of the object will define the columns that are inserted.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  unless Array.isArray fields
    row = fields
    fields = Object.keys(fields)
  unless fields?.length
    throw new Error "Column list is required when constructing an INSERT"
  iq = new InsertQuery {table}
  # TODO this is gross
  iq.q.columns = iq.q.nodes[1] = new Tuple fields
  iq.addRow(row) if row
  return iq

exports.select = (table, fields) ->
  ###
  Create a new :class:`queries/select::SelectQuery` selecting from ``table``.

  :param table: Table name to select rows from.
  :param fields: (Optional) Fields to project from ``table``. If this is not
    given, all fields (``*``) will be projected until
    :meth:`queries/select::SelectQuery.fields`` is called.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  query = new SelectQuery {table}
  if fields?
    query.fields fields...
  query

exports.update = (table) ->
  ###
  Create a new :class:`queries/update::UpdateQuery` that will update ``table``.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new UpdateQuery {table}

exports.delete = (table) ->
  ###
  Create a new :class:`queries/delete::DeleteQuery` that will delete rows from
  ``table``.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new DeleteQuery {table}

maybeVisit = (func) ->
  (args...) ->
    if typeof args[args.length - 1] is 'function'
      cb = args.pop()
      func(args...).visit(cb)
    else
      func args...

for name, func of exports
  exports[name] = maybeVisit(func)
  exports[name.toUpperCase()] = exports[name]
  exports[name[0].toUpperCase() + name.substring(1)] = exports[name]
