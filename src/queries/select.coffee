SUDQuery = require './sud'
{ Node,
  getAlias,
  Select,
  And,
  Join,
  toRelation,
  sqlFunction,
  JOIN_TYPES } = require '../nodes'

module.exports = class SelectQuery extends SUDQuery
  ###
  Adds a number of SELECT-specific methods to :class:`queries/sud::SUDQuery`,
  such as `fields` and `groupBy`
  ###
  @rootNode = Select

  fields: (fields) ->
    ###
    Adds one or more fields to the query. Fields can be strings (in which case
    they will be passed to :meth:`queries/sud::SUDQuery.project`) or pre-
    constructed nodes. (Such as those returned by ``project``).

    If no fields are given, clears all fields from the currently focused table.

    To alias a field, use an object with a single key where the key is the alias
    name and the value is a string or node::

      q.fields({employee_name: 'employees.name'})

    ###
    if fields.length == 0
      rel = @q.relations.active
      @q.projections.prune((p) -> p.rel() is rel)
      return

    proj = (o) => if o instanceof Node then o else @project(o)

    for f in fields
      if alias = getAlias f
        f = f[alias]
        @q.projections.addNode proj(f).as(alias)
      else
        @q.projections.addNode proj(f)
    null

  func: (fun, args) ->
    ###
    Adds a SQL function to the column list for the query. This can be an
    aggregate function if you also use :meth:`queries/select::groupBy`.

    :param fun: name of SQL function.
    :param args: arguments that will be passed to the function. Any argument
      that is not a `Node` object will be converted into a bound parameter.

    Example::

      # SELECT count(id) FROM t1
      select('t1', function (q) { q.agg('count', q.c('id')) })

      # SELECT count(id) AS "counter" FROM t1
      select('t1', function (q) { q.agg({counter: 'count'}, q.c('id')) })

    ###
    if alias = getAlias fun
      @q.projections.addNode sqlFunction(fun[alias], args).as(alias)
    else
      @q.projections.addNode sqlFunction(fun, args)

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
    :param opts.fields: Columns to be selected from the newly joined table.
    ###
    rel = toRelation table
    if @q.relations.get rel.ref(), false
      throw new Error "Table/alias #{rel.ref()} is not unique!"

    type = opts.type || JOIN_TYPES.INNER
    if type not instanceof JOIN_TYPES.INNER.constructor
      throw new Error "Invalid join type #{type}, try the constant types exported in the base module (e.g. INNER)."
    join = new Join type, rel
    @q.relations.addNode join
    # must switch to the new relation before making clauses
    if opts.on then join.on(new And(@_makeClauses opts.on))
    if opts.fields?
      @fields(opts.fields)

  ensureJoin: (table, opts={}) ->
    ###
    The same as :meth:`join`, but will only join ``tbl`` if it is **not**
    joined already.
    ###
    rel = toRelation table
    if not @q.relations.get rel.ref(), false
      @join rel, opts

  focus: (alias) ->
    ###
    Make a different table "focused", this will use that table as the default
    for the ``fields``, ``order`` and ``where`` methods.

    :param alias: The table/alias name to focus. If the table or alias is not
      already part of the query an error will be thrown.
    ###
    @q.relations.switch alias

  groupBy: (fields) ->
    ### Add a GROUP BY to the query. ###
    @q.groupBy.addNode(@project(field)) for field in fields
    null

  having: (constraint) ->
    ###
    This method works similarly to :meth:`queries/sud::SUDQuery.where`, but the
    constraints are added the `HAVING` portion of a SQL clause.
    ###
    @q.having.addNode(node) for node in @_makeClauses(constraint)


fluid     = require '../decorators/fluid'
variadic  = require '../decorators/variadic'
deprecate = require '../decorators/deprecate'

SelectQuery::[method] = variadic(SelectQuery::[method]) for method in [
  'fields', 'groupBy'
]

SelectQuery::[method] = fluid(SelectQuery::[method]) for method in [
  'distinct', 'fields', 'func', 'join', 'ensureJoin', 'focus', 'groupBy', 'having'
]

# Aliased methods
SelectQuery::field = SelectQuery::fields

# Deprecated methods
SelectQuery::agg = deprecate.rename SelectQuery::func, ".agg", ".func"
