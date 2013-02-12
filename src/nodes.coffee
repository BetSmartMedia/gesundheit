###
These are the classes that represent nodes in the AST for a SQL statement.
Application code should very rarely have to deal with these classes directly;
Instead, the APIs exposed by the various query manager classes are intended to
cover the majority of use-cases.

However, in the spirit of "making hard things possible", all of AST nodes are
exported from this module so you can constructed and assemble them manually if
you need to.
###

class Node
  ### (Empty) base Node class ###
  render: (dialect) ->
    throw new Error "#{@constructor} has no render method. Parents: #{dialect.path}"


class ValueNode extends Node
  ### A ValueNode is a literal string that should be printed unescaped. ###
  constructor: (@value) ->
    if @value?
      throw new Error("Invalid #{@constructor.name}: #{@value}") unless @valid()
  copy: -> new @constructor @value
  valid: -> true
  render: -> @value

class IntegerNode extends ValueNode
  ### A :class:`nodes::ValueNode` that validates it's input is an integer. ###
  valid: -> not isNaN @value = parseInt @value

class Identifier extends ValueNode
  ###
  An identifier is a column or relation name that may need to be quoted.
  ###
  render: (dialect) ->
    dialect.quote(@value)

CONST_NODES = {}
CONST_NODES[name] = new ValueNode(name.replace('_', ' ')) for name in [
  'DEFAULT', 'NULL', 'IS_NULL', 'IS_NOT_NULL'
]

class JoinType extends ValueNode

JOIN_TYPES = {}
JOIN_TYPES[name] = new JoinType(name.replace('_', ' ')) for name in [
  'LEFT', 'RIGHT', 'INNER',
  'LEFT_OUTER', 'RIGHT_OUTER', 'FULL_OUTER'
  'NATURAL', 'CROSS'
]

class NodeSet extends Node
  ### A set of nodes joined together by ``@glue`` ###
  constructor: (nodes, glue=' ') ->
    ###
    :param @nodes: A list of child nodes.
    :param glue: A string that will be used to join the nodes when rendering
    ###
    @nodes = []
    @addNode(node) for node in nodes if nodes
    @glue ?= glue

  copy: ->
    ###
    Make a deep copy of this node and it's children
    ###
    c = new @constructor @nodes.map(copy), @glue
    return c

  addNode: (node) ->
    ### Add a new Node to the end of this set ###
    @nodes.push node

  params: ->
    ###
    Recurse over child nodes, collecting parameter values.
    ###
    params = []
    for node in @nodes when node.params?
      params = params.concat node.params()
    params

  render: (dialect) ->
    @nodes.map((n) -> dialect.render(n)).filter((n) -> n).join(@glue)
   

class FixedNodeSet extends NodeSet
  # A NodeSet that disables the ``addNode`` method after construction.
  constructor: ->
    super
    @addNode = null

class Statement extends Node
  # A Statement lazily constructs child nodes.
  @prefix = ''

  # Define the names and type of each lazily built child node
  @structure = (structure) ->
    @_nodeOrder = []
    structure.forEach ([k, type]) =>
      @_nodeOrder.push k
      @::__defineGetter__ k, -> @_private[k] or= new type
      @::__defineSetter__ k, (v) -> @_private[k] = v

  constructor: (opts) ->
    @_private = {}
    @initialize(opts) if opts

  initialize: (opts) ->
    @initialize = null

  copy: ->
    c = new @constructor
    for k, node of @_private
      c[k] = copy node
    c.initialize = null
    return c

  render: (dialect) ->
    parts = for k in @constructor._nodeOrder when node = @_private[k]
      dialect.render(node)
    if parts.length
      @constructor.prefix + parts.join(' ')
    else
      ''

  params: ->
    ###
    Collect parameters from child nodes.
    ###
    params = []
    for node in (@_private[k] for k in @constructor._nodeOrder) when node?.params
      params = params.concat node.params()
    params


class ParenthesizedNodeSet extends NodeSet
  ### A NodeSet wrapped in parenthesis. ###
  render: ->
    "(" + super + ")"

class AbstractAlias extends Node
  constructor: (@obj, @alias) ->
  copy: -> new @constructor copy(@obj), @alias
  render: (dialect) ->
    dialect.maybeParens(dialect.render(@obj)) + " AS " + dialect.quote(@alias)

# End of generic base classes

class TextNode extends Node
  constructor: (@text, @bindVals=[]) ->

  paramRegexp = /\$([\w]+)\b/g

  render: (dialect) ->
    @text.replace paramRegexp, (_, name) =>
      if name of @bindVals
        dialect.render(new Parameter(@bindVals[name]))
      else
        throw new Error "Parameter #{name} not present in #{@bindVals}"

  params: ->
    if Array.isArray(@bindVals)
      @bindVals
    else
      (v for k, v of @bindVals)

  as: (alias) ->
    new AbstractAlias @, alias


class SqlFunction extends Node
  ### Includes :class:`nodes::ComparableMixin` ###
  constructor: (@name, @arglist) ->
  copy: -> new @constructor @name, copy(@arglist)
  render: (dialect) -> "#{@name}#{dialect.render @arglist}"
  as: (alias) -> new Alias @, alias

  @Alias = class Alias extends AbstractAlias
    render: (dialect, parents) ->
      if parents.some((node) -> node instanceof ProjectionSet)
        super
      else
        dialect.quote(@alias)

class Parameter extends ValueNode
  ###
  Like a ValueNode, but will render as a bound parameter place-holder
  (e.g. ``$1``) and it's value will be collected by
  :meth:`nodes::NodeSet.params`
  ###
  render: (dialect) -> "?"
  params: -> [@value]

class Relation extends Identifier
  ###
  A relation node represents a table name or alias in a statement.
  ###
  ref: ->
    ###
    Return the table name. Aliased tables return the alias name.
    ###
    @value

  project: (field) ->
    ### Return a new :class:`nodes::Projection` of `field` from this table. ###
    new Projection @, toField(field)

  as: (alias) ->
    new Alias @, alias

  @Alias = class Alias extends AbstractAlias
    ### An aliased :class:`nodes::Relation` ###
    ref: -> @alias
    project: (field) -> Relation::project.call @, field
    render: (dialect, parents) ->
      if parents.some((n) -> n instanceof Projection)
        dialect.quote(@alias)
      else
        super

class Field extends Identifier
  ### A column name ###

class Projection extends FixedNodeSet
  ###
  Includes :class:`nodes::ComparableMixin`
  ###
  constructor: (@source, @field) -> super [@source, @field], '.'
  rel: -> @source
  copy: -> new @constructor copy(@source), copy(@field)
  as: (alias) ->
    new Alias @, alias

  @Alias = class Alias extends AbstractAlias
    ### An aliased :class:`nodes::Projection` ###
    rel: -> @obj.rel()
    render: (dialect, parents) ->
      if parents.some((n) -> n instanceof ProjectionSet)
        super
      else
        dialect.quote(@alias)

class Limit extends IntegerNode
  render: ->
    if @value then "LIMIT #{@value}" else ""

class Offset extends IntegerNode
  render: ->
    if @value then "OFFSET #{@value}" else ""

class Binary extends FixedNodeSet
  constructor: (@left, @op, @right) -> super [@left, @op, @right], ' '
  copy: -> new @constructor copy(@left), @op, copy(@right)

  and: (args...) ->
    new And [@, args...]

  or: ->
    new Or [@, args...]

  render: (dialect) ->
    [dialect.render(@left), dialect.operator(@op), dialect.render(@right)].join(' ')

class Tuple extends ParenthesizedNodeSet
  glue: ', '

class ProjectionSet extends NodeSet
  ### The list of projected columns in a query ###
  glue: ', '

class Returning extends ProjectionSet
  render: ->
    if string = super then "RETURNING #{string}" else ""

class Distinct extends ProjectionSet
  constructor: (@enable=false) -> super

  copy: -> new @constructor @enable, copy(@nodes)

  render: (dialect) ->
    if not @enable
      ''
    else if @nodes.length
      "DISTINCT(#{super})"
    else
      'DISTINCT'

class SelectProjectionSet extends ProjectionSet
  prune: (predicate) ->
    ###
    Recurse over child nodes, removing all Projection nodes that match the
    predicate.
    ###
    @nodes = @nodes.filter((n) -> not predicate(n))

  render: (dialect) ->
    if not @nodes.length
      '*'
    else
      super


#######
class RelationSet extends NodeSet
  ###
  Manages a set of relations and exposes methods to find them by alias.
  ###
  addNode: (node) ->
    unless @first
      @relsByName = {}
      @nodes.push node
      @first = @active = @relsByName[node.ref()] = node
    else
      super
      @active = @relsByName[node.ref()] = node.relation

  copy: ->
    c = super
    if @active?.ref?() isnt c.active?.ref?()
      c.switch(@active.ref())
    return c

  get: (name, strict=true) ->
    name = name.ref() unless 'string' == typeof name
    found = @relsByName[name]
    if strict and not found
      throw new Error "No such relation #{name} in #{Object.keys @relsByName}"
    return found

  switch: (name) ->
    @active = @get(name)

  render: (dialect) ->
    if string = super then "FROM #{string}" else ""

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
    c = new @constructor copy(@type), copy(@relation)
    for clause in @nodes.slice(4)
      c.on(clause)
    return c


class Where extends NodeSet
  glue: ' AND '
  render: (dialect) ->
    if string = super then "WHERE #{string}" else ""

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
  glue: ', '
  render: (dialect) ->
    if string = super then "GROUP BY #{string}" else ""

class OrderBy extends NodeSet
  constructor: (os) -> super os, ', '
  render: (dialect) ->
    if string = super then "ORDER BY #{string}" else ""

class Ordering extends FixedNodeSet
  constructor: (projection, direction) ->
    super [projection, direction]

class Select extends Statement
  ###
  The root node of a SELECT query
  ###
  @prefix = 'SELECT '
  
  @structure [
    ['distinct',    Distinct]
    ['projections', SelectProjectionSet]
    ['relations',   RelationSet]
    ['where',       Where]
    ['groupBy',     GroupBy]
    ['orderBy',     OrderBy]
    ['limit',       Limit]
    ['offset',      Offset]
  ]

  initialize: (opts) ->
    @projections  # ensure we have an (empty) projection set
    if opts.table
      @relations.addNode toRelation(opts.table)

class Update extends Statement
  ###
  The root node of an UPDATE query
  ###

  class UpdateSet extends NodeSet
    # must be pre-defined for the call to @structure below
    constructor: (nodes) -> super nodes, ', '
    render: (dialect) ->
      if string = super then "SET #{string}" else ""

  @prefix = 'UPDATE '

  @structure [
    ['relation',  Relation]
    ['updates',   UpdateSet]
    ['orderBy',   OrderBy]
    ['limit',     Limit]
    ['fromList',  RelationSet] # Optional FROM portion
    ['where',     Where]
    ['returning', Returning]
  ]

  initialize: (opts) ->
    @relation = toRelation(opts.table)


class Insert extends Statement
  ###
  The root node of an INSERT query
  ###

  class InsertData extends NodeSet
    # must be pre-defined for the call to @structure below
    glue: ', '
    render: (dialect) ->
      if string = super then "VALUES #{string}" else ""

  @prefix = 'INSERT INTO '

  @structure [
    ['relation',  Relation]
    ['columns',   Tuple]
    ['data',      InsertData]
    ['returning', Returning]
  ]

  initialize: (opts) ->
    unless opts.fields?.length
      throw new Error "Column list is required when constructing an INSERT"
    @columns = new Tuple opts.fields
    @relation = toRelation(opts.table)

  addRow: (row) ->
    if @data instanceof Select
      throw new Error "Cannot add rows when inserting from a SELECT"
    if Array.isArray(row) then @addRowArray row
    else @addRowObject row

  addRowArray: (row) ->
    if not count = @columns.nodes.length
      throw new Error "Must set column list before inserting arrays"
    if row.length != count
      throw new Error "Wrong number of values in array, expected #{@columns.nodes}"

    params = for v in row
      if v instanceof Node then v else new Parameter v
    @data.addNode new Tuple params

  addRowObject: (row) ->
    ###
    Add a row from an object. This will set the column list of the query if it
    isn't set yet. If it `is` set, then only keys matching the existing column
    list will be inserted.
    ###
    @addRowArray @columns.nodes.map(valOrDefault.bind(row))

  valOrDefault = (key) ->
    #key = field.value
    if @hasOwnProperty(key) then @[key] else CONST_NODES.DEFAULT

  from: (query) ->
    unless query instanceof Select
      throw new Error "Can only insert from a SELECT"
    @data = query

  addReturning: (cols) ->
    for col in cols
      @returning.addNode toField(col)
    return


class Delete extends Statement
  ###
  The root node of a DELETE query
  ###
  @prefix = 'DELETE '
  @structure [
    ['relations', RelationSet]
    ['where',     Where]
    ['orderBy',   OrderBy]
    ['limit',     Limit]
  ]

  initialize: (opts) ->
    @relations.addNode(toRelation(opts.table))

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
  TextNode::[k] = v
  SqlFunction::[k] = v
  SqlFunction.Alias::[k] = v
  Projection::[k] = v
  Projection.Alias::[k] = v

toParam = (it) ->
  ###
  Return a Node that can be used as a parameter.

    * :class:`queries/select::SelectQuery` instances will be treated as
      un-named sub queries,
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
    when Relation, Relation.Alias then it
    when String then new Relation it
    when Object
      if alias = getAlias it
        toRelation(it[alias]).as(alias)
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

      count = sqlFunction('count', [new ValueNode('*')])

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

  If you find yourself using this function often, please consider opening an
  issue on `Github <https://github.com/BetSmartMedia/gesundheit>`_ with details
  on your use case so gesundheit can support it more elegantly.
  ###
  new TextNode(rawSQL, bindVals)

binaryOp = (left, op, right) ->
  ###
  Create a new :class:`nodes::Binary` node::

    binaryOp('hstore_column', '->', toParam(y))
    # hstore_column -> ?

  This is for special cases, normally you want to use the methods from
  :class:`nodes::ComparableMixin`.
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
  ValueNode
  IntegerNode
  Identifier
  JoinType
  NodeSet
  FixedNodeSet
  Statement
  ParenthesizedNodeSet
  TextNode
  SqlFunction
  Parameter
  Relation
  Field
  Projection
  Limit
  Offset
  Binary
  Tuple
  ProjectionSet
  Returning
  Distinct
  SelectProjectionSet
  RelationSet
  Join
  Where
  Or
  And
  GroupBy
  OrderBy
  Ordering
  Select
  Update
  Insert
  Delete
  ComparableMixin
}

copy = (it) ->
  # Return a deep copy of ``it``.
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
