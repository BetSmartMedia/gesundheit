{inspect}      = require 'util'
{EventEmitter} = require 'events'
{toRelation}   = require '../nodes'
assert         = require 'assert'
fluidize       = require '../fluid'


module.exports = class BaseQuery extends EventEmitter
  ###
  The base class for all queries. While this class itself is not part of
  gesundheits public API, the methods defined on it are.
  ###
  @rootNode = null

  constructor: (engine, opts={}) ->
    ###
    :param engine: The engine the query will be bound to.

    :param opts.table:
      a ``String``, ``Relation``, ``Alias``, or object literal with a single
      key and value which will be interpreted as an alias name and table,
      respectively. This is normally given to as the first parameter to the
      query creation functions in :mod:`queries/index`
    ###
    @bind(engine)
    if table = opts.table
      table = toRelation table
    @q = new @constructor.rootNode table

  copy: ->
    ### Instantiate a new query with a deep copy of this ones AST ###
    c = new @constructor @engine
    c.q = @q.copy()
    c.bind(@engine)
    return c

  visit: (fn) ->
    ###
    Call the given function in the context of this query. This is useful with
    query factory functions where you can use it as a sort-of-DSL::

        SELECT('people', ['name'], function(q) {
          // this === q
          this.join('addresses', {
            on: {person_id: q.project('people', 'id')},
            fields: ['city', 'region']
          })
        })

    ###
    fn.call @

  bind: (engine) ->
    ###
    Bind this query object to a new engine.
    If no argument is given the query will be bound to the default engine.
    ###
    oldEngine = @engine
    @engine = engine or require('../').defaultEngine
    if @engine isnt oldEngine
      oldEngine?.unextendQuery?(@)
      @engine.extendQuery?(@)

    assert @engine?.query, "Engine has no query method: #{inspect @engine}"
    assert @engine?.render, "Engine has no render method: #{inspect @engine}"

  render: ->
    ###
    Render the query to a SQL string.
    ###
    @engine.render @q

  compile: ->
    ###
    Compile this query object, returning a SQL string and parameter array.
    ###
    [@render(), @q.params()]

  execute: (cb) ->
    ###
    Execute the query using ``@engine`` and return a `QueryAdapter`.

    :param cb: An (optional) node-style callback that will be called with any
      errors and/or the query results. If no callback is given, a new EventEmitter
      will be returned that emits either an 'error' or 'result' event.
    ###
    @engine.query.apply(@engine, @compile().concat(cb))

  toString: ->
    @render()

fluidize BaseQuery, 'bind', 'visit'
