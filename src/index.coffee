###
There are a few subsystems that make up gesundheit, but the majority of use
cases will be covered by using the following properties of the main module:

  **gesundheit.{Select, SELECT, select}**
    Function for creating new :class:`queries/select::SelectQuery` instances.

  **gesundheit.{Update, UPDATE, update}**
    Function for creating new :class:`queries/update::UpdateQuery` instances.

  **gesundheit.{Delete, DELETE, delete}**
    Function for creating new :class:`queries/delete::DeleteQuery` instances.

  **gesundheit.{Insert, INSERT, insert}**
    Function for creating new :class:`queries/insert::InsertQuery` instances.

  **gesundheit.engine**
    Function for creating new :mod:`engines`.

  **gesundheit.defaultEngine**
    The engine that will be used for queries that aren't explicitly bound. This
    is set to a no-op engine that you will want to replace with either an object
    returned by the ``gesundheit.engine`` function or by implementing the engine
    interface yourself.

  **Join types**
    Constant nodes for use with :meth:`queries/sud::SUDQuery.join`.
    'LEFT', 'RIGHT', 'INNER', 'LEFT_OUTER', 'RIGHT_OUTER', 'FULL_OUTER'
    'NATURAL', 'CROSS'

  **AST helper functions**
    These come from the `nodes <#module-nodes::>`_ module and are often useful
    when constructing complicated queries:

      :func:`nodes::toParam`
        Convert any object to a parameter placeholder.
      :func:`nodes::toRelation`
        Convert various inputs to :class:`nodes::Relation` nodes.
      :func:`nodes::binaryOp`
        Create a binary comparison node manually.  (e.g. for postgres' custom
        operators).
      :func:`nodes::sqlFunction`
        Create SQL function calls (e.g. ``MAX(last_update)``)
      :func:`nodes::text`
        Include raw SQL in a query, with parameter placeholders.

If you are implementing support for a different database engine or constructing
particularly unusual SQL statements, you might also want to make use of these:

  **gesundheit.nodes**
    The `nodes <Nodes>` module.

  **gesundheit.dialects**
    The `dialects <Dialects>` module.

###
exports.dialects = require './dialects'
exports.engine   = require './engine'
exports.nodes    = require './nodes'

exports.queries  = require('./queries/index')

exports.defaultEngine = exports.engine 'fake://localhost/'

exports.queries.mixinFactoryMethods(exports, -> exports.defaultEngine)

for name, node of exports.nodes.CONST_NODES
  exports[name] = exports.nodes.CONST_NODES[name]

for name, node of exports.nodes.JOIN_TYPES
  exports[name] = exports.nodes.JOIN_TYPES[name]

for name, helper of exports.nodes when name[0] is name[0].toLowerCase()
  exports[name] = helper

exports.begin = (args...) ->
  exports.defaultEngine.begin args...
  
exports.query = (args...) ->
  exports.defaultEngine.query args...

exports.unmarshaller = require('./unmarshal')
