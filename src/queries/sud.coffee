BaseQuery = require './base'
nodes = require '../nodes'
fluidize = require '../fluid'
{Node, And, Or, OrderBy, Projection, CONST_NODES, toField} = nodes

module.exports = class SUDQuery extends BaseQuery
  ###
  SUDQuery is the base class for SELECT, UPDATE, and DELETE queries. It adds
  logic to :class:`queries/base::BaseQuery` for dealing with WHERE clauses and
  ordering.
  ###

  where: (constraint) ->
    ###
    Adds a WHERE clause to the query. This method accepts wide range of input
    that can express very complex constraints. The examples below assume we are
    starting with this simple select query: ``q = select('t1')``

    The first kind of constraint is a comparison node as produced by the
    :class:`nodes::ComparableMixin` methods on projected fields::

      q.where(q.p('field1').eq(42))
      q.where(q.p('field2').gt(42))
      # WHERE t1.field1 = 42 AND t1.field2 > 42

    We used an implied table name above, which is always the last table added to
    the query or focused with  :meth:`queries/sud::SUDQuery.focus`. If you want
    to specify constraints on multiple tables at once (or just be more explicit)
    you can also specify the relation for a field by prepending it to the field
    name (e.g. ``q.p('t1.field1')``. See :meth:`queries/sud::SUDQuery.project`
    for details.

    The second kind of constraint is an object literal where each key is a field
    name and each value is a constraint. The last example expressed as a literal
    object looks like this::

      q.where({field1: 42, field2: {gt: 42}})
      # WHERE t1.field1 = 42 AND t1.field2 > 42

    Internally this constructs the comparison nodes for you using a simple
    transformation: each key is passed to project (meaning you can specify the
    relation name as part of the key if you so desire) and each value is either
    used as the argument to :meth:`nodes::ComparableMixin.eq` or (in the case of
    object literals) converted into one or more calls to the corresponding
    comparison methods.

    To compare two fields, use a projection as the value to be compared::

      p = q.project.bind(q, 't1')
      q.where({field1: {gt: p('field2')}})
      # WHERE t1.field1 > t1.field2

    If you use either of the special keys ``'and'`` or ``'or'`` in an object,
    the value will be treated as a nested set of constraints to be joined with
    the corresponding SQL operator. This process is recursive so you can nest
    constraints arbitrarily deep::

      q.where({or: {a: 1, and: {b: 2, c: 3}}})
      # WHERE (t1.a = 1 OR (t1.b = 2 AND t1.c = 3))

    You can also acheive the same effect by chaining method calls on comparison
    nodes::

      a = q.p('a')
      b = q.p('b')
      c = q.p('c')
      q.where(a.eq(1).or(b.eq(2).and(c.eq(3))))
      # WHERE (t1.a = 1 OR (t1.b = 2 AND t1.c = 3))

    If you have the need to mix both styles (or simply find it more readable,
    You can use an array of constraints as the value for ``'or'`` or ``'and'``::

      q.where({or: [{a: 1}, b.eq(2).and(c.eq(3))]})

    Note that currently you **cannot** pass an object literal to the ``.and``
    and ``.or`` methods::

      # Will not work!!
      q.where(a.eq(1).or({b: 2, c: 3}))

    Finally, there are also shortcut methods :meth:`queries/sud::SUDQuery.and`
    and :meth:`queries/sud::SUDQuery.or` that treat multiple arguments like an
    array of constraints.
    ###
    @q.where.addNode(node) for node in @_makeClauses(constraint)

  _makeClauses: (constraint) ->
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
          clauses = clauses.concat(@_makeClauses(item))
      return clauses

    if constraint instanceof Node
      return [constraint]

    for field, predicate of constraint
      if field is 'and'
        clauses.push new And @_makeClauses(predicate)
      else if field is 'or'
        clauses.push new Or @_makeClauses(predicate)
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
    ### Shortcut for ``.where({or: clauses})`` ###
    @where or: clauses

  and: (clauses...) ->
    ### Shortcut for ``.where({and: clauses})`` ###
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
      field = toField(field)
      if typeof relation is 'string'
        new Projection @q.relations.get(relation), field
      else
        # Make sure this relation is part of our query
        relation = @q.relations.get(toRelation(relation).ref())
        new Projection relation, field
    else if typeof relation is 'string'
      parts = relation.split '.'
      if parts.length is 2
        new Projection @q.relations.get(parts[0]), toField(parts[1])
      else
        new Projection @defaultRel(), toField(relation)  # Actually the field
    else if relation instanceof Projection
      proj = relation
      # Check that the source of this projection is in our query
      @q.relations.get(proj.source?.ref())
      proj
    else
      throw new Error("Can't make a projection from object: #{relation}")

  rel: (alias) ->
    ### A shorthand way to get a relation by (alias) name ###
    @q.relations.get alias


fluidize SUDQuery, 'where', 'or', 'and', 'limit', 'offset', 'order'

SUDQuery::p = SUDQuery::project
