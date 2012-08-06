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
  if fields and typeof fields is 'object' and not Array.isArray fields
    row = fields
    fields = Object.keys(row)
  unless fields?.length
    throw new Error "Column list is required when constructing an INSERT"
  iq = new InsertQuery @, {table}
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
  query = new SelectQuery @, {table}
  if fields?
    query.fields fields...
  query

exports.update = (table) ->
  ###
  Create a new :class:`queries/update::UpdateQuery` that will update ``table``.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new UpdateQuery @, {table}

exports.delete = (table) ->
  ###
  Create a new :class:`queries/delete::DeleteQuery` that will delete rows from
  ``table``.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new DeleteQuery @, {table}

exports.mixinFactoryMethods = (proxy, getEngine) ->
  ###
  Add wrappers methods for each of the query factory functions to ``invocant``
  The added methods will :meth:`~queries/base::BaseQuery.bind` the query
  objects they create to the engine returned by ``getEngine`` before returning
  them.

  If ``getEngine`` is not given, queries will be bound to ``proxy`` itself.
  ###
  getEngine ?= -> proxy
  ['insert', 'select', 'update', 'delete'].forEach (type) ->
    wrapper = -> exports[type].apply(getEngine(), arguments)
    proxy[type] = wrapper
    proxy[type.toUpperCase()] = wrapper
    proxy[type[0].toUpperCase() + type.substring(1)] = wrapper

maybeVisit = (func) ->
  ->
    a = [].slice.call(arguments)
    if typeof a[a.length - 1] is 'function'
      cb = a.pop()
      func.apply(@, a).visit(cb)
    else
      func.apply(@, a)

for name in ['insert', 'select', 'update', 'delete']
  func = exports[name]
  exports[name] = maybeVisit(func)
  exports[name.toUpperCase()] = exports[name]
  exports[name[0].toUpperCase() + name.substring(1)] = exports[name]
