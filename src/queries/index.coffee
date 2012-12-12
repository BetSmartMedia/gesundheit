###
The factory functions defined here create instances of the corresponding
`*Query` manager classes, which fit the following inheritance hierarchy:

  * BaseQuery

    * InsertQuery

    * SUDQuery

      * SelectQuery

      * UpdateQuery

      * DeleteQuery

.. _query-factories:

These functions are the same ones re-exported by the main gesundheit module
(where they bind queries to ``gesundheit.defaultEngine``), and attached to
engine/transaction objects (where they bind queries to the engine/transaction
they are called on).

Each one accepts a table name or alias object (anything handled by
:func:`nodes::toRelation`), one or more extra parameters, and an optional
visitor callback as a final parameter that will be called with it's ``this``
context set to the newly constructed query instance.
###

InsertQuery = require './insert'
SelectQuery = require './select'
UpdateQuery = require './update'
DeleteQuery = require './delete'

INSERT = (table, fieldsOrRow) ->
  ###
  Create a new :class:`queries/insert::InsertQuery` that will add rows to
  ``table``.

  :param table: Name of the table that rows will be inserted into.
  :param fieldsOrRow: Either an array of column names that will be inserted, or a
    plain object representing a row of data to insert, in which case the keys
    of the object will define the columns that are inserted.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.

  .. warning::
    The column names passed in ``fields`` will be printed into the query
    **unescaped** so do **not** use arbitrary input here. This is hopefully only temporary.
  ###
  if Array.isArray fieldsOrRow
    fields = fieldsOrRow
  else if typeof fieldsOrRow is 'object'
    row = fieldsOrRow
    fields = Object.keys(row)
  iq = new InsertQuery @, {table, fields}
  iq.addRow(row) if row
  return iq

SELECT = (table, fields) ->
  ###
  Create a new :class:`queries/select::SelectQuery` selecting from ``table``.

  :param table: Name or alias object of the first table to select rows from.
    More tables can be joined using :meth:`queries/select::SelectQuery.join`.
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

  :param table: Name or alias of the table to update.
  :param visitor: (Optional) a function that will be called with it's context
    set to the newly constructed query object.
  ###
  new UpdateQuery @, {table}

DELETE = (table) ->
  ###
  Create a new :class:`queries/delete::DeleteQuery` that will delete rows from
  ``table``.

  :param table: Name or alias of the table to delete rows from.
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
  invocant

maybeVisit = (func) ->
  ->
    a = [].slice.call(arguments)
    if typeof a[a.length - 1] is 'function'
      cb = a.pop()
      func.apply(@, a).visit(cb)
    else
      func.apply(@, a)
