{inspect}      = require 'util'
{EventEmitter} = require 'events'
{toRelation}   = require '../nodes'
assert         = require 'assert'


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
      Any object that can be converted by :func:`nodes::toRelation`.
    ###
    @bind(engine)
    @q = opts.rootNode or new @constructor.rootNode opts

  copy: (fn) ->
    ### Instantiate a new query with a deep copy of this ones AST ###
    query = new @constructor @engine, rootNode: @q.copy()
    if (fn) then query.visit(fn) else query

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
    fn.call @, @

  bind: (engine) ->
    ###
    Bind this query object to a new engine.
    If no argument is given the query will be bound to the default engine.
    ###
    oldEngine = @engine
    @engine = engine or require('../index').defaultEngine
    if @engine isnt oldEngine
      oldEngine?.unextendQuery?(@)
      @engine.extendQuery?(@)

    assert @engine?.query, "Engine has no query method: #{inspect @engine}"
    assert @engine?.compile, "Engine has no compile method: #{inspect @engine}"

  render: ->
    ###
    Render the query to a SQL string.
    ###
    @compile()[0]

  compile: ->
    ###
    Compile this query object, returning a SQL string and parameter array.
    ###
    @engine.compile(@q)

  execute: (cb) ->
    ###
    Execute the query using ``@engine`` and return a `QueryAdapter`.

    :param cb: An (optional) node-style callback that will be called with any
      errors and/or the query results. If no callback is given, an `AnyDB Query`_
      will be returned.

    .. _AnyDB Query: https://github.com/grncdr/node-any-db/blob/master/DESIGN.md#query-adapters
    ###
    try
      args = @compile()
      args.push(cb)
    catch err
      # create a useless emitter to return
      emitter = new EventEmitter
      process.nextTick ->
        if cb then cb(err) else emitter.emit('error', err)
      return emitter

    @engine.query.apply(@engine, args)

  toString: ->
    @render()

  toJSON: ->
    {_type: @constructor.name, q: @q.toJSON()}


fluid = require '../decorators/fluid'

BaseQuery::[method] = fluid(BaseQuery::[method]) for method in ['bind', 'visit']
