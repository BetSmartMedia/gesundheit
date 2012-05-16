fluidize = require '../fluid'
SUDQuery = require './sud'
{Alias, getAlias, Select, And, Join, toRelation, sqlFunction, JOIN_TYPES} = require '../nodes'

module.exports = class SelectQuery extends SUDQuery
  ###
  Adds a number of SELECT-specific methods to :class:`queries/sud::SUDQuery`,
  such as `fields` and `groupBy`
  ###
  @rootNode = Select

  fields: (fields...) ->
    ###
    Adds one or more fields to the query. If the second argument is an array, 
    the first argument is treated as a table (in the same way that :meth:`join` 
    understands tables) and the second argument as the list of fields to 
    select/update from that table. The table **must** already be joined for this
    to work.

    If the second argument is not an array, then each argument is treated as an 
    individual field to be projected from the currently focused table.
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

      select('t1').agg('count', 'id') # SELECT count(id) FROM t1
    
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

  join: (table, opts={}) ->
    ###
    Join another table to the query.

    :param table: A table name, or alias literal. An error will be thrown if
      the table/alias name is not unique. See :func:`nodes::toRelation` for
      more information on the many things ``table`` could be.
    :param opts.on:
      An object literal expressing join conditions. See
      :meth:`queries/select::SelectQuery::where` for more.
    :param opts.type: A join type constant (e.g. INNER, OUTER)
    :param opts.fields: A list of fields to be projected from the newly joined table.
    ###
    rel = toRelation table
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

  ensureJoin: (table, opts={}) ->
    ###
    The same as :meth:`join`, but will only join ``tbl`` if it is **not**
    joined already.
    ###
    rel = toRelation table
    if not @q.relations.get rel.ref(), false
      @join tbl, opts

  rel: (alias) ->
    ### A shorthand way to get a relation by (alias) name ###
    @q.relations.get alias

  project: (alias, field) ->
    ###
    Return a :class:`nodes::Projection` node representing ``<alias>.<field>``.

    This node has a number methods from :class:`nodes::ComparableMixin` that can
    create new comparison nodes usable in join conditions and where clauses::

      # Find developers over the age of 45
      s = select('people', ['name'])
      dep_id = s.project('people', 'department_id')
      s.join('departments', on: {id: dep_id})
      s.where(s.project('departments', 'name').eq('development'))
      s.where(s.project('people', 'age').gte(45))

    ###
    @q.relations.get(alias, true).project(field)

  focus: (alias) ->
    ###
    Make a different table "focused", this will use that table as the default
    for the ``fields``, ``order`` and ``where`` methods.

    :param alias: The table/alias name to focus. If the table or alias is not
      already part of the query an error will be thrown.
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

fluidize SelectQuery,
  'distinct', 'fields', 'agg', 'join', 'ensureJoin', 'focus', 'groupBy'

SelectQuery::field = SelectQuery::fields
