fluid = require '../fluid'
BaseQuery = require './base'
{Or, OrderBy} = require '../nodes'

# SUDQuery is the base class for SELECT, UPDATE, and DELETE queries. It adds
# logic to `BaseQuery` for dealing with WHERE clauses and ordering.
module.exports = class SUDQuery extends BaseQuery

# Add a WHERE clause to the query. Can optionally take a table/alias name as the
# first parameter, otherwise the clause is added using the last table added to
# the query.
#
# The where clause itself is an object where each key is treated as field name
# and each value is treated as a constraint. Constraints can be literal values
# or objects, in which case each key of the constraint is treated as an
# operator, and each value must be a literal value. Supported operators are
# determined by the dialect of the query. See dialect/mysql.coffee for an
# example.
  where: fluid (alias, predicate) ->
    if predicate?
      rel = @q.relations.get alias
      unknown 'table', alias unless rel?
    else
      predicate = alias
      rel = @defaultRel()

    if predicate.constructor != Object
      return @q.where.addNode predicate

    @q.where.addNode (@makeClauses rel, predicate)...

# Add one or more WHERE clauses, all joined by the OR operator
  or: fluid (args...) ->
    rel = @defaultRel()
    clauses = []
    for arg in args
      clauses.push (@makeClauses rel, arg)...
    @q.where.addNode new Or clauses

  makeClauses: (rel, predicate) ->
    clauses = []
    for field, constraint of predicate
      if Object == constraint.constructor
        for op, val of constraint
          clauses.push rel.project(field).compare op, val
      else
        clauses.push rel.project(field).eq constraint
    clauses

# Add an ORDER BY to the query. Currently this *always* uses the last table
# added to the query.
#
# Each ordering can either be a string, in which case it must be a valid-ish
# SQL snippet like 'some_field DESC', (the field name and direction will still
# be normalized) or an object, in which case each key will be treated as a
# field and each value as a direction.
  orderBy: fluid (args...) ->
    rel = @defaultRel()
    orderings = []
    for orderBy in args
      switch orderBy.constructor
        when String
          orderings.push orderBy.split ' '
        when OrderBy
          @q.orderBy.addNode orderBy
        when Object
          for name, dir of orderBy
            orderings.push [name, dir]
        else
          throw new Error "Can't turn #{orderBy} into an OrderBy object"

    for [field, direction] in orderings
      direction = switch (direction || '').toLowerCase()
        when 'asc',  'ascending'  then 'ASC'
        when 'desc', 'descending' then 'DESC'
        when '' then ''
        else throw new Error "Unsupported ordering direction #{direction}"
      @q.orderBy.addNode new OrderBy(rel.project(field), direction)

  limit: fluid (l) -> @q.limit.value = l
  offset: fluid (l) -> @q.offset.value = l

  defaultRel: -> @q.relations.active

# A helper for throwing Errors
unknown = (type, val) -> throw new Error "Unknown #{type}: #{val}"
