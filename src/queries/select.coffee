fluid = require '../fluid'
SUDQuery = require './sud'
{Alias, Select, And, Join, toRelation, sqlFunction, INNER} = require '../nodes'

# Our friend the SELECT query. Select adds ORDER BY and GROUP BY support.
module.exports = class SelectQuery extends SUDQuery
  constructor: (opts={}) ->
    super Select, opts

# Adds one or more fields to the query. If the second argument is an array, 
# the first argument is treated as a table (in the same way that `join` 
# understands tables) and the second argument as the list of fields to 
# select/update from that table. The table must already be joined for this to 
# work.

# If the second argument is not an array, then each argument is treated as an 
# individual field of the last table added to the query.
  fields: fluid (fields...) ->
    if fields[1] and Array.isArray fields[1]
      rel = @q.relations.get fields[0]
      unknown 'table', fields[0] unless rel?
      fields = fields[1]
    else
      rel = @q.relations.active

    if fields.length == 0
      @q.projections.prune((p) -> p.source == rel)
      return

    for f in fields
      if alias = Alias.getAlias f
        f = f[alias]
        @q.projections.addNode new Alias rel.project(f), alias
      else
        @q.projections.addNode rel.project f

# Adds one or more aggregated fields to the query
  agg: fluid (fun, fields...) ->
    @q.projections.addNode sqlFunction fun, fields

  join: fluid (tbl, opts={}) ->
    rel = toRelation tbl
    if @q.relations.get rel.ref(), false
      throw new Error "Table/alias #{rel.ref()} is not unique!"

    type = opts.type || INNER
    if type not instanceof INNER.constructor
      throw new Error "Invalid join type #{type}, try the constant types exported in the base module (e.g. INNER)."
    joinClause = opts.on && new And(@makeClauses rel, opts.on)
    @q.relations.addNode new Join type, rel, joinClause
    @q.relations.registerName rel
    @q.relations.switch rel
    if opts.fields?
      @fields(opts.fields...)

# A shorthand way to get a relation by name
  rel: (alias) -> @q.relations.get alias

# Make a different table "active", this will use that table as the default for 
# the ``fields``, ``orderBy`` and ``where`` methods
  from: fluid (alias) -> @q.relations.switch alias


# Add a GROUP BY to the query.
  groupBy: fluid (fields...) ->
    rel = @q.relations.active
    for field in fields
      if field.constructor == String
        @q.groupBy.addNode rel.project field
      else if field instanceof Projection
        @q.groupBy.addNode field

SelectQuery::field = SelectQuery::fields

SelectQuery.from = (tbl, fields, opts={}) ->
  if fields? and fields.constructor != Array
    opts = fields
    fields = null
  opts.table = tbl
  query = new SelectQuery opts
  if fields?
    query.fields fields...
  return query

