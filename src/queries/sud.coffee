BaseQuery = require './base'
nodes = require '../nodes'
fluidize = require '../fluid'
{Node, And, Or, OrderBy, CONST_NODES} = nodes

module.exports = class SUDQuery extends BaseQuery
  ###
  SUDQuery is the base class for SELECT, UPDATE, and DELETE queries. It adds
  logic to :class:`queries/base::BaseQuery` for dealing with WHERE clauses and
  ordering.
  ###

  where: (constraint) ->
    ###
    Add a WHERE clause to the query.

    The where clause itself can be a comparison node, such as those produced by
    the :class:`nodes::ComparableMixin` methods::

      q.where(q.p('table','field1').eq(42))
      q.where(q.p('table','field2').gt(42))

    ... Or an object literal where each key is a field name (or field name
    alias) and each value is a constraint::

      q.where({field1: 42, field2: {gt: 42}})

    Constraint values can also be other projected fields::

      p = q.project.bind(q, 'table')
      q.where('table', p('field1').gt(p('field2')))


    To create a set of constraints joined by the OR operator, use 'or' as a key in
    the object literal with an array of further constraints. Similarly, you can use
    'and' as a key to nest 'and' constraints within an OR, nesting clauses arbitrarily
    deep.

      select('t').where({or: [{a: 1, and: [{b: 2, c: 3}]}]})

    Will generate the SQL statement::

      SELECT * FROM t WHERE (t.a = 1 OR (t.b = 2 AND t.c = 3))

    ###
    @q.where.addNode(node) for node in @makeClauses(constraint)

  makeClauses: (constraint) ->
    ###
    Return an array of Binary, And, and Or nodes for this constraint object
    ###
    clauses = []

    # Recursive call from 'and' and 'or' object keys
    if Array.isArray(constraint)
      for item in constraint
        if item instanceof Node
          clauses.push(item)
        else
          clauses = clauses.concat(@makeClauses(item))
      return clauses

    if constraint instanceof Node
      return [constraint]

    for field, predicate of constraint
      if field is 'and'
        clauses.push new And @makeClauses(predicate)
      else if field is 'or'
        debugger
        clauses.push new Or @makeClauses(predicate)
      else
        column = @project field
        if predicate is null
          clauses.push column.compare 'IS', CONST_NODES.NULL
        else if predicate.constructor is Object
          for op, val of predicate
            clauses.push column.compare op, val
        else
          clauses.push column.eq predicate
    clauses

  or: (clauses...) ->
    ### Shortcut for ``.where({or: clauses}) ###
    @where or: clauses

  and: (clauses...) ->
    @where and: clauses

  order: (args...) ->
    ###
    Add an ORDER BY to the query. Currently this *always* uses the "active"
    table of the query. (See :meth:`queries/select::SelectQuery.from`)

    Each ordering can either be a string, in which case it must be a valid-ish
    SQL snippet like 'some_field DESC', (the field name and direction will still
    be normalized) or an object, in which case each key will be treated as a
    field and each value as a direction.
    ###
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

  limit: (l) ->
    ### Set the LIMIT on this query ###
    @q.limit.value = l

  offset: (l) ->
    ### Set the OFFSET of this query ###
    @q.offset.value = l

  defaultRel: ->
    @q.relations.active

  project: (relation, field) ->
    ###
    Return a :class:`nodes::Projection` node representing ``<relation>.<field>``.

    The first argument is optional and specifies a table or alias name referring
    to a relation already joined to this query. If you don't specify a relation,
    the table added or focused last will be used. Alternatively, you can specify
    the relation name and field with a single dot-separated string::

      q.project('departments.name') == q.project('departments', 'name')

    The returned object has a methods from :class:`nodes::ComparableMixin` that
    can create new comparison nodes usable in join conditions and where clauses::

      # Find developers over the age of 45
      s = select('people', ['name'])
      s.join('departments', on: {id: s.project('people', 'department_id')})
      s.where(s.project('departments', 'name').eq('development'))
      s.where(s.project('people', 'age').gte(45))

    ``project`` is also aliased as ``p`` for those who value brevity::

         q.where(q.p('departments.name').eq('development'))

    .. note:: this means you *must* specify a relation name if you have a field
      name with a dot in it, if you have dots in your column names, sorry.

    ###
    if field?
      rel = @q.relations.get(relation, true)
    else
      field = relation
      rel_field = field.split('.')
      if rel_field.length is 2
        field = rel_field[1]
        rel = @q.relations.get(rel_field[0], true)
      else
        rel = @defaultRel()
    rel.project(field)

fluidize SUDQuery, 'where', 'or', 'and', 'limit', 'offset', 'order'

SUDQuery::p = SUDQuery::project
