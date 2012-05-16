fluidize = require '../fluid'
SUDQuery = require './sud'
{Alias, getAlias, Select, And, Join, toRelation, sqlFunction, JOIN_TYPES} = require '../nodes'

module.exports = class SelectQuery extends SUDQuery
  ###
  Our friend the ``SELECT`` query. Select adds :meth:`orderBy` and
  :meth:`groupBy` methods to :class:`queries/sud::SUDQuery`.

  It is idiomatic to create new ``SelectQuery`` instances using
  :func:`queries/select::SelectQuery.from`
  ###

  fields: (fields...) ->
    ###
    Adds one or more fields to the query. If the second argument is an array, 
    the first argument is treated as a table (in the same way that :meth:`join` 
    understands tables) and the second argument as the list of fields to 
    select/update from that table. The table **must** already be joined for this
    to work.

    If the second argument is not an array, then each argument is treated as an 
    individual field to be projected from the last table added to the query.
    ###
    if fields[1] and Array.isArray fields[1]
      rel = @q.relations.get fields[0]
      unknown 'table', fields[0] unless rel?
      fields = fields[1]
    else
      rel = @q.relations.active

    if fields.length == 0
      @q.projections.prune((p) -> p.source == rel)
      return

    project = (f) -> if typeof f is 'object' then f else rel.project(f)

    for f in fields
      if alias = getAlias f
        f = f[alias]
        @q.projections.addNode new Alias project(f), alias
      else
        @q.projections.addNode project(f)

  agg: (fun, fields...) ->
    ###
    Adds one or more aggregated fields to the query

    :param fun: name of SQL aggregation function.
    :param fields: Fields to be projected from the current table and passed
      as arguments to ``fun``

    Example::

      select.from('t1').agg('count', 'id') # SELECT count(id) FROM t1
    
    ###
    if alias = getAlias fun
      fun = fun[alias]
    funcNode = sqlFunction fun, fields
    if alias
      @q.projections.addNode new Alias funcNode, alias
    else
      @q.projections.addNode funcNode


  distinct: (bool) ->
    ###
    Make this query DISTINCT on *all* fields.
    ###
    @q.distinct.enable = bool

  join: (tbl, opts={}) ->
    ###
    Join another table to the query.

    :param tbl: A string tablename, will be processed by :func:`nodes::toRelation`
    :param opts.on: An object literal expressing join conditions. See :func:`where`
    :param opts.type: A join type constant (e.g. INNER, OUTER)
    :param opts.fields: A list of fields to be projected from the newly joined table.
    ###
    rel = toRelation tbl
    if @q.relations.get rel.ref(), false
      throw new Error "Table/alias #{rel.ref()} is not unique!"

    type = opts.type || JOIN_TYPES.INNER
    if type not instanceof JOIN_TYPES.INNER.constructor
      throw new Error "Invalid join type #{type}, try the constant types exported in the base module (e.g. INNER)."
    joinClause = opts.on && new And(@makeClauses rel, opts.on)
    @q.relations.addNode new Join type, rel, joinClause
    @q.relations.registerName rel
    @q.relations.switch rel
    if opts.fields?
      @fields(opts.fields...)

  ensureJoin: (tbl, opts={}) ->
    ###
    The same as :meth:`join`, but will only join ``tbl`` if it is **not**
    joined already.
    ###
    rel = toRelation tbl
    if not @q.relations.get rel.ref(), false
      @join tbl, opts

  rel: (alias) ->
    ### A shorthand way to get a relation by name ###
    @q.relations.get alias

  project: (alias, field) ->
    ###
    Return an AST node representing ``<alias>.<field>``.
    See :class:`nodes::Projection` for methods supported by the returned node.
    ###
    @q.relations.get(alias, true).project(field)

  focus: (alias) ->
    ###
    Make a different table "active", this will use that table as the default for 
    the ``fields``, ``orderBy`` and ``where`` methods

    :param alias: The table/alias name to focus. If the table or alias is not
      already part of the query an Error will be thrown.
    ###
    @q.relations.switch alias

  groupBy: (fields...) ->
    ### Add a GROUP BY to the query. ###
    rel = @q.relations.active
    for field in fields
      if field.constructor == String
        @q.groupBy.addNode rel.project field
      else
        @q.groupBy.addNode field

fluidize SelectQuery, 'distinct', 'fields', 'agg', 'join', 'ensureJoin', 'from', 'groupBy'

SelectQuery::field = SelectQuery::fields

SelectQuery.from = (table, fields, opts={}) ->
  ###
  Factory function for new SelectQuery instances

  :param table: Table name to select rows from.
  :param fields: (Optional) Fields to select from ``table``.
  :param opts: Additional options for :meth:`queries/base::BaseQuery.constructor`
  ###
  if fields? and fields.constructor != Array
    opts = fields
    fields = null
  opts.table = table
  query = new SelectQuery Select, opts
  if fields?
    query.fields fields...
  return query


