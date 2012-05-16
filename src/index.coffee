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

  **gesundheit.engines.{mysql, postgres}**
    Functions for creating new :mod:`engines`.

  **gesundheit.defaultEngine**
    The engine that will be used for queries that aren't explicitly bound. This
    is set to a no-op engine that you will want to replace either using the
    ``gesundheit.engines`` functions or by implementing the engine interface
    yourself.

  **Join types**
    Constant nodes for use with :meth:`queries/sud::SUDQuery.join`.
    'LEFT', 'RIGHT', 'INNER', 'LEFT_OUTER', 'RIGHT_OUTER', 'FULL_OUTER'
    'NATURAL', 'CROSS'

  **AST helper functions**
    These come from the `nodes <Nodes>`_ module and are often useful when
    constructing queries that the query manager classes don't cover as well:

      * :func:`nodes::toParam`
      * :func:`nodes::toRelation`
      * :func:`nodes::binaryOp`
      * :func:`nodes::sqlFunction`
      * :func:`nodes::text`

If you are implementing support for a different database engine or constructing
particularly unusual SQL statements, you might also want to make use of these:

  **gesundheit.nodes**
    The `nodes <Nodes>` module.

  **gesundheit.dialects**
    The `dialects <Dialects>` module.

###
exports.dialects = require './dialects'
exports.engines = require './engines'
exports.defaultEngine = exports.engines.fakeEngine()

exports.nodes = require './nodes'

for name, node of exports.nodes.CONST_NODES
  exports[name] = exports.nodes.CONST_NODES[name]

for name, node of exports.nodes.JOIN_TYPES
  exports[name] = exports.nodes.JOIN_TYPES[name]

for name, helper of exports.nodes when name[0] is name[0].toLowerCase()
  exports[name] = helper

for name, func of require('./queries')
  exports[name] = func
  exports[name.toUpperCase()] = func
  exports[name[0].toUpperCase() + name.substring(1)] = func
