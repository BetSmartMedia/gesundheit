###
The query manager classes use the following inheritance hierarchy:

  * BaseQuery

    * InsertQuery

    * SUDQuery

      * SelectQuery

      * UpdateQuery

      * DeleteQuery

The following functions for creating \*Query class instances are re-exported
by the main gesundheit module:
###

{Tuple} = require './../nodes'
InsertQuery = require './insert'
SelectQuery = require './select'
UpdateQuery = require './update'
DeleteQuery = require './delete'

exports.insert = (tbl, fields, opts={}) ->
  ###
  Create a new :class:`queries/insert::InsertQuery` that will add rows to
  ``table``.

  The fields parameter is **required** to be an array of column names that
  will be inserted.
  ###
  unless fields?.length
    throw new Error "Column list is required when constructing an INSERT"
  opts.table = tbl
  iq = new InsertQuery opts
  # TODO this is gross
  iq.q.columns = iq.q.nodes[1] = new Tuple fields
  return iq

exports.select = (table, fields, opts={}) ->
  ###
  Create a new :class:`queries/select::SelectQuery` selecting from ``table``.

  :param table: Table name to select rows from.
  :param fields: (Optional) Fields to project from ``table``. If this is not
    given, all fields (``*``) will be projected until
    :meth:`queries/select::SelectQuery.fields`` is called.
  :param opts: Additional options for :meth:`queries/base::BaseQuery.constructor`
  ###
  if fields? and fields.constructor != Array
    opts = fields
    fields = null
  opts.table = table
  query = new SelectQuery opts
  if fields?
    query.fields fields...
  query

exports.update = (table, opts={}) ->
  ###
  Create a new :class:`queries/update::UpdateQuery` that will update ``table``.
  ###
  opts.table = table
  new UpdateQuery opts

exports.delete = (table, opts={}) ->
  ###
  Create a new :class:`queries/delete::DeleteQuery` that will delete rows from
  ``table``.
  ###
  opts.table = table
  q = new DeleteQuery opts

for name of exports
  exports[name.toUpperCase()] = exports[name]
  exports[name[0].toUpperCase() + name.substring(1)] = exports[name]
