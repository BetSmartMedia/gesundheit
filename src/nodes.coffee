###
These are the classes that represent nodes in the AST for a SQL statement.
Application code should very rarely have to deal with these classes directly;
Instead, the APIs exposed by the various query manager classes are intended to
cover the majority of use-cases. However, in the spirit of "making hard things
possible", the various AST nodes can be constructed and assembled manually if you
so desire.
###

class Node
  ### (Empty) base Node class ###

class ValueNode extends Node
  ### A ValueNode is a literal string that should be printed unescaped. ###
  constructor: (@value) ->
    if @value?
      throw new Error("Invalid #{@constructor.name}: #{@value}") unless @valid()
  copy: -> new @constructor @value
  valid: -> true

class IntegerNode extends ValueNode
  valid: -> not isNaN @value = parseInt @value

class Identifier extends ValueNode
  ###
  An identifier is a column or relation name, that may need to be quoted
  in the SQL string.
  ###

CONST_NODES = {}
CONST_NODES[name] = new ValueNode name.replace '_', ' ' for name in [
  'DEFAULT', 'NULL', 'IS_NULL', 'IS_NOT_NULL'
]

class JoinType extends ValueNode

JOIN_TYPES = {}
JOIN_TYPES[name] = new ValueNode name.replace '_', ' ' for name in [
  'LEFT', 'RIGHT', 'INNER',
  'LEFT_OUTER', 'RIGHT_OUTER', 'FULL_OUTER'
  'NATURAL', 'CROSS'
]

class NodeSet extends Node
  ### A set of nodes joined together by ``@glue`` ###
  constructor: (@nodes=[], glue=' ') ->
    ###
    :param @nodes: A list of child nodes.
    :param glue: A string that will be used to join the nodes when rendering
    ###
    @glue ||= glue

  copy: ->
    ###
    Make a deep copy of this node and it's children
    ###
    c = new @constructor
    c.nodes = copy @nodes
    return c

  addNode: (node) ->
    ### Add a new Node to the end of this set ###
    @nodes.push node

  params: ->
    ###
    Recurse over nested NodeSet instances, collecting parameter values.
    ###
    params = []
    for node in @nodes
      if node.params?
        params = params.concat node.params()
      else if node.constructor is Parameter
        params.push node.value
    params

class FixedNodeSet extends NodeSet
  ### A NodeSet that disables the ``addNode`` method after construction. ###
  constructor: (nodes, glue) ->
    super nodes, glue
    @addNode = null

class FixedNamedNodeSet extends FixedNodeSet
  ###
  A FixedNodeSet that instantiates a set of nodes defined by the class member
  ``@structure`` when it it instantiated.

  See :class:`nodes::Select` for example.
  ###
  constructor: ->
    nodes = for [k, type] in @constructor.structure
      @[k] = new type
    super nodes

  copy: ->
    c = super()
    for i, [k, _] of @constructor.structure
      c[k] = c.nodes[i]
    return c

class ParenthesizedNodeSet extends NodeSet
  ### A NodeSet wrapped in parenthesis. ###

# End of generic base classes

class SqlFunction extends Node
  ### Includes :class:`nodes::ComparableMixin` ###
  constructor: (@name, @arglist) ->
  copy: -> new @constructor @name, copy(@arglist)

class Alias extends Node
  ###
  Example::

     table = new Relation('my_table_with_a_long_name')
     alias = new Alias(table, 'mtwaln')

  ###
  constructor: (@obj, @alias) ->
  copy: -> new @constructor copy(@obj), @alias
  project: (name) -> new Projection @, name
  field: -> @project arguments
  ref: -> @alias

class Parameter extends ValueNode
  ###
  Like a ValueNode, but will render as a bound parameter place-holder
  (e.g. ``$1``) and it's value will be collected by
  :meth:`nodes::NodeSet.params`
  ###

class Relation extends Identifier
  ###
  A relation node represents a table name or alias in a statement.
  ###
  ref: ->
    ###
    Return the table name. This is a common interface with :class:`nodes:Alias`.
    ###
    @value

  project: (field) ->
    ### Return a new :class:`nodes::Projection` of `field` from this table. ###
    new Projection @, toField(field)

class Field extends Identifier
  ### A column name ###

class Projection extends FixedNodeSet
  ###
  Includes :class:`nodes::ComparableMixin`
  ###
  constructor: (@source, @field) -> super [@source, @field], '.'
  copy: -> new @constructor copy(@source), @field

class Limit extends IntegerNode
class Offset extends IntegerNode

class Binary extends FixedNodeSet
  constructor: (@left, @op, @right) -> super [@left, @op, @right], ' '
  copy: -> new @constructor copy(@left), @op, copy(@right)

  and: (args...) ->
    new And [@, args...]

  or: ->
    new Or [@, args...]

class Tuple extends ParenthesizedNodeSet
  ### A tuple node. e.g. (col1, col2) ###
  glue: ', '

class ProjectionSet extends NodeSet
  ### The list of projected columns in a query ###
  glue: ', '

class Returning extends ProjectionSet

class Distinct extends ProjectionSet
  constructor: (@enable=false) -> super

class SelectProjectionSet extends ProjectionSet
  prune: (predicate) ->
    ###
    Recurse over child nodes, removing all Projection nodes that match the
    predicate.
    ###
    orig = @nodes
    @nodes = []
    for node of orig
      if node instanceof Projection
        if not predicate node then @nodes.push node
      else if node instanceof Alias
        if not predicate node.obj then @nodes.push node

#######
class RelationSet extends NodeSet
  ###
  Manages a set of relations and exposes methods to find them by alias.
  ###
  start: (@first) ->
    @byName = {}
    @nodes.unshift @first
    @byName[@first.ref()] = @active = @first
    delete @start

  registerName: (node) -> @byName[node.ref()] = node

  copy: ->
    c = super()
    if first = c.nodes.shift() then c.start first
    for node in c.nodes
      rel = node.relation || node
      c.registerName rel
    if first then c.active = c.get @active
    return c

  get: (name, strict=true) ->
    name = name.ref() unless 'string' == typeof name
    rel = @byName[name]
    if not rel and strict
      throw new Error "No such relation #{name} in #{Object.keys @byName}"
    return rel

  switch: (name) ->
    @active = @get(name)

class Join extends FixedNodeSet
  constructor: (@type, @relation) ->
    nodes = [@type, 'JOIN', @relation]
    super nodes

  on: (clause) ->
    if @nodes.length < 4
      @nodes.push 'ON'
    @nodes.push clause

  ref: ->
    @relation.ref()

  copy: ->
    c = super
    c.type = c.nodes[0]
    c.relation = c.nodes[2]
    return c

#####
class Where extends NodeSet
  glue: ' AND '

class Or extends ParenthesizedNodeSet
  glue: ' OR '

  and: (args...) ->
    new And [@, args...]

  or: (args...) ->
    ret = @copy()
    ret.addNode(arg) for arg in args
    return ret


class And extends ParenthesizedNodeSet
  glue: ' AND '

  and: (args...) ->
    ret = @copy()
    ret.addNode(arg) for arg in args
    return ret

  or: (args...) ->
    new Or [@, args...]

class GroupBy extends NodeSet
  constructor: (gs) -> super gs, ', '

class OrderBySet extends NodeSet
  constructor: (os) -> super os, ', '

class OrderBy extends FixedNodeSet
  constructor: (projection, direction) -> super [projection, direction]

class UpdateSet extends NodeSet
  constructor: (nodes) -> super nodes, ', '

class Select extends FixedNamedNodeSet
  @structure = [
    ['distinct',    Distinct]
    ['projections', SelectProjectionSet]
    ['relations',   RelationSet]
    ['where',       Where]
    ['groupBy',     GroupBy]
    ['orderBy',     OrderBySet]
    ['limit',       Limit]
    ['offset',      Offset]
  ]

  constructor: (rel) -> super(); @relations.start rel if rel

class Update extends FixedNamedNodeSet
  @structure = [
    ['relation',  Relation]
    ['updates',   UpdateSet]
    ['orderBy',   OrderBySet]
    ['limit',     Limit]
    ['fromList',  RelationSet] # Optional FROM portion
    ['where',     Where]
    ['returning', Returning]
  ]
  constructor: (rel) -> super(); @relation = @nodes[0] = rel if rel

class InsertData extends NodeSet
  glue: ', '

class Insert extends FixedNamedNodeSet
  @structure = [
    ['relation',  Relation]
    ['columns',   Tuple]
    ['source',    InsertData]
    ['returning', Returning]
  ]
  constructor: (rel) -> super(); @relation = @nodes[0] = rel if rel

  addRow: (row) ->
    if @source.constructor == Select
      throw new Error "Cannot add rows when inserting from a SELECT"
    if row.constructor == Array then @addRowArray row
    else @addRowObject row

  addRowArray: (row) ->
    if not count = @columns.nodes.length
      throw new Error "Must set column list before inserting arrays"
    if row.length != count
      fields = (n for n in @columns.nodes)
      throw new Error "Wrong number of values in array, expected #{fields}"

    params = for v in row
      if v instanceof Node then v else new Parameter v
    @source.addNode new Tuple params

  addRowObject: (row) ->
    ###
    Add a row from an object. This will set the column list of the query if it
    isn't set yet. If it _is_ set, then only keys matching the existing column
    list will be inserted.
    ###
    array = for f in @columns.nodes
      if row[f]? or row[f] == null then row[f] else CONST_NODES.DEFAULT
    @addRowArray array


class Delete extends FixedNamedNodeSet
  @structure = [
    ['relations', RelationSet]
    ['where',     Where]
    ['orderBy',   OrderBySet]
    ['limit',     Limit]
  ]

  constructor: (rel) -> super(); @relations.start rel if rel

class ComparableMixin
  ###
  A mixin that adds comparison methods to a class. Each of these comparison
  methods will yield a new AST node comparing the invocant to the argument.
  ###
  eq:  (other) ->
    ### ``this = other`` ###
    new Binary @, '=',  toParam other
  ne: (other) ->
    ### ``this <> other`` ###
    new Binary @, '<>', toParam other
  gt: (other) ->
    ### ``this > other`` ###
    new Binary @, '>',  toParam other
  lt: (other) ->
    ### ``this < other`` ###
    new Binary @, '<',  toParam other
  lte: (other) ->
    ### ``this <= other`` ###
    new Binary @, '<=', toParam other
  gte: (other) ->
    ### ``this >= other`` ###
    new Binary @, '>=', toParam other
  compare: (op, other) ->
    ### ``this op other`` **DANGER** `op` is **NOT** escaped! ###
    new Binary @, op, toParam other

for k, v of ComparableMixin::
  Projection::[k] = v
  SqlFunction::[k] = v

toParam = (it) ->
  ###
  Return a Node that can be used as a parameter.

    * SelectQuery instances will be treated as un-named sub queries,
    * Node instances will be returned unchanged.
    * Arrays will be turned into a :class:`nodes::Tuple` instance.

  All other types will be wrapped in a :class:`nodes::Parameter` instance.
  ###
  SelectQuery = require './queries/select'
  if it?.constructor is SelectQuery then new Tuple([it.q])
  else if it instanceof Node then it
  else if Array.isArray it then new Tuple(it.map toParam)
  else new Parameter it

toRelation = (it) ->
  ###
  Transform ``it`` into a :class:`nodes::Relation` instance.

  This accepts `strings, `Relation`` and ``Alias`` instances, and objects with
  a single key-value pair, which will be turned into an ``Alias`` instance.

  Examples::

     toRelation('some_table')     # new Relation('some_table')
     toRelation(st: 'some_table') # new Alias(Relation('some_table'), 'st')
     toRelation(new Relation('some_table')) # returns same instance
     toRelation(new Alias(new Relation('some_table'), 'al') # returns same instance

  **Throws Errors** if the input is not valid.
  ###
  switch it.constructor
    when Relation, Alias then it
    when String then new Relation it
    when Object
      if alias = getAlias it
        new Alias(new Relation(it[alias]), alias)
      else
        throw new Error "Can't make relation out of #{it}"
    else
      throw new Error "Can't make relation out of #{it}"


toField = (it) ->
  if typeof it is 'string'
    new Field it
  else if it instanceof Field
    it
  else
    throw new Error "Can't make a field out of #{it}"


toProjection = (relation, field) ->
  ###
  Create a new :class:`nodes::Projection` instance.

  The first argument is optional and specifies a table (or alias) name.
  Alternatively, you can specify the relation name and field with a single
  dot-separated string::

    toProjection('departments.name') == toProjection('departments', 'name')

  Either argument can be an pre-constructed node object (of the correct type).
  ###
  if field?
    new Projection(toRelation(relation), toField(field))
  else if typeof relation is 'string' and (parts = relation.split('.')).length is 2
    new Projection(toRelation(parts[0]), toField(parts[1]))
  else
    throw new Error("Can't make projection from object: #{relation}")


sqlFunction = (name, args) ->
  ###
  Create a new SQL function call node. For example::

      count = sqlFunction('count', new ValueNode('*'))

  ###
  new SqlFunction name, new Tuple(args)

getAlias = (o) ->
  ###
  Check if ``o`` is an object literal representing an alias, and return the
  alias name if it is.
  ###
  if 'object' == typeof o
    keys = Object.keys(o)
    return keys[0] if keys.length == 1
  return null

paramRegexp = /\$([\w]+)\b/g
text = (rawSQL, bindVals) ->
  ###
  Construct a node with a raw SQL string and (optionally) parameters. Useful for
  when you want to construct a query that is difficult or impossible with the
  normal APIs. [#]_

  To use bound parameters in the SQL string, use ``$`` prefixed names, and
  pass a ``bindVals`` argument with corresponding property names. For example,
  :meth:`~queries/sud::SUDQuery.where` doesn't (currently) support the SQL
  ``BETWEEN`` operator, but if you needed it, you could use ``text``::

      function peopleInWeightRange (min, max, callback) {
        return select('people')
          .where(text("weight BETWEEN $min AND $max", {min: min, max: max}))
          .execute(callback)
      }

  Because javascript doesn't distinguish between array indexing and property
  access, it can be more clear to use numbered parameters for such short
  snippets::

      function peopleInWeightRange (min, max, callback) {
        return select('people')
          .where(text("weight BETWEEN $0 AND $1", [min, max]))
          .execute(callback)
      }

  .. rubric:: Footnotes

  .. [#] If you find yourself using this function often, please consider opening
    an issue on `Github <https://github.com/BetSmartMedia/gesundheit>`_ with
    details on your use case so gesundheit can support it more elegantly.

  ###
  nodes = []
  lastIndex = 0
  while match = paramRegexp.exec rawSQL
    if match.index > lastIndex
      nodes.push new ValueNode rawSQL.substring(lastIndex, match.index)
    nodes.push new Parameter bindVals[match[1]]
    lastIndex = paramRegexp.lastIndex

  if lastIndex is 0
    new ValueNode rawSQL
  else
    nodes.push new ValueNode rawSQL.substring(lastIndex)
    new FixedNodeSet nodes, ''

binaryOp = (left, op, right) ->
  ###
  Create a new :class:`nodes::Binary` node::

    binaryOp('hstore_column', '->', toParam(y))
    # hstore_column -> ?

  .. seealso::

    :meth:`queries/select::SelectQuery.project`
       Returns :class:`nodes::Projection` objects that have comparison methods
       from :class:`nodes::ComparableMixin`.

  ###
  new Binary left, op, right

module.exports = {
  CONST_NODES
  JOIN_TYPES

  binaryOp
  getAlias
  sqlFunction
  text
  toField
  toRelation
  toParam

  Node
  Alias
  And
  Or
  Join
  OrderBy
  Projection
  Tuple
  FixedNamedNodeSet

  Select
  Update
  Insert
  Delete
}

copy = (it) ->
  ###
  Return a deep copy of ``it``.
  ###
  if not it then return it
  switch it.constructor
    when String, Number, Boolean then it
    when Array then it.map copy
    when Object
      c = {}
      for k, v of it
        c[k] = copy v
    else
      if it.copy? then it.copy()
      else throw new Error "Don't know how to copy #{it}"
