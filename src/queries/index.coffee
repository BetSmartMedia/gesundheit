###
Queries are build using the factory functions in this module
The query manager classes use the following inheritance hierarchy:

  * BaseQuery

    * InsertQuery

    * SUDQuery

      * SelectQuery

      * UpdateQuery

      * DeleteQuery

The query factory functions defined here are re-exported by the main gesundheit
module. They each accept an optional visitor callback as a final parameter that
will be passed to the :meth:`~queries/base::BaseQuery.visit` method of the
newly created query.
###

{Tuple}     = require './../nodes'
InsertQuery = require './insert'
SelectQuery = require './select'
UpdateQuery = require './update'
DeleteQuery = require './delete'

INSERT = (table, fieldsOrRow) ->
  ###
  Create a new :class:`queries/insert::InsertQuery` that will add rows to
  ``table``.

  :param fieldsOrRow: Either an array of column names that will be inserted, or a
    plain object representing a row of data to insert, in which case the keys
    of the object will define the columns that are inserted.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  if fieldsOrRow and typeof fieldsOrRow is 'object'
    if Array.isArray fieldsOrRow
      fields = fieldsOrRow
    else
      row = fieldsOrRow
      fields = Object.keys(row)
  unless fields?.length
    throw new Error "Column list is required when constructing an INSERT"
  iq = new InsertQuery @, {table}
  # TODO this is gross
  iq.q.columns = iq.q.nodes[1] = new Tuple fields
  iq.addRow(row) if row
  return iq

SELECT = (table, fields) ->
  ###
  Create a new :class:`queries/select::SelectQuery` selecting from ``table``.

  :param table: Table name to select rows from.
  :param fields: (Optional) Fields to project from ``table``. If this is not
    given, all fields (``*``) will be projected until
    :meth:`queries/select::SelectQuery.fields` is called.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  query = new SelectQuery @, {table}
  if fields?
    query.fields fields...
  query

UPDATE = (table) ->
  ###
  Create a new :class:`queries/update::UpdateQuery` that will update ``table``.

  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new UpdateQuery @, {table}

DELETE = (table) ->
  ###
  Create a new :class:`queries/delete::DeleteQuery` that will delete rows from
  ``table``.

  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new DeleteQuery @, {table}

exports.mixinFactoryMethods = (invocant, getEngine) ->
  ###
  Add wrappers methods for each of the query factory functions to ``invocant``
  using lower, UPPER, and Camel cases. The new methods will retrieve an engine
  using ``getEngine`` and then create the query bound to that engine.

  If ``getEngine`` is not given, queries will be bound to ``invocant`` instead.
  ###
  getEngine ?= -> invocant
  for type, factory of {INSERT, SELECT, UPDATE, DELETE} then do (type, factory) ->
    factory = maybeVisit(factory)
    wrapper = -> factory.apply(getEngine(), arguments)
    invocant[type] = wrapper
    invocant[type.toLowerCase()] = wrapper
    invocant[type[0] + type.toLowerCase().substring(1)] = wrapper

maybeVisit = (func) ->
  ->
    a = [].slice.call(arguments)
    if typeof a[a.length - 1] is 'function'
      cb = a.pop()
      func.apply(@, a).visit(cb)
    else
      func.apply(@, a)
