{toRelation} = require '../nodes'
assert = require 'assert'
fluidize = require '../fluid'


module.exports = class BaseQuery
  ###
  The base class for all queries. While this class itself is not part of
  gesundheits public API, the methods defined on it are.
  ###
  @rootNode = null

  constructor: (opts={}) ->
    ###
    :param opts.table: a ``String``, ``Relation``, ``Alias``, or an object
      literal with a single key and value which will be interpreted as an alias
      name and table, respectively. This is given to as the first parameter to
      the query creation functions in :mod:`queries/index`
    :param opts.bind: (optional) an :mod:`engine` or connection that the
      query will be bound to. The engine is used to render and/or execute the
      query. If not given ``gesundheit.defaultEngine`` will be used.
    ###
    @doEcho = false
    @bind(opts.binding)
    if (table = opts.table)?
      table = toRelation table
    @q = new @constructor.rootNode table

  copy: ->
    ### Instantiate a new query with a deep copy of this ones AST ###
    c = new @constructor ->
    c.q = @q.copy()
    c.engine = @engine
    return c

  visit: (fn) ->
    ###
    Call the given function in the context of this query. This is mostly useful
    in coffeescript where you can use it as a sort-of-DSL::
        
        queryObject.visit ->
          @where x: val
          @orderBy x: 'ASC'
    
    The current query is also given as the first parameter to the query in
    case you need it.
    ###
    fn.call @, @ if fn?

  echo: ->
    ###
    If called before .render(), then resulting SQL will be sent to stdout
    via console.log()
    ###
    @doEcho = true

  bind: (bindable=null) ->
    ###
    Bind this query object to a `bindable` object (engine or client).
    If no argument is given the query will be bound to the default engine.
    ###
    oldEngine = @engine

    # We are binding to a specific client object
    if bindable?.engine
      @client = bindable
      @engine = bindable.engine
    else if bindable
      @engine = bindable
    else if not @engine
      # Bind to the defaultEngine
      @engine = require('../').defaultEngine
    if @engine isnt oldEngine
      oldEngine.unextend(@) if oldEngine?.unextend
      @engine.extend(@) if @engine.extend

    assert @engine?.connect
    assert @engine?.render

  render: ->
    ###
    Render the query to SQL.

    :param bindable: (optional)
      If present, the query will be bound to this object using :meth:`bind`
    ###
    sql = @engine.render @q
    console.log sql if @doEcho
    console.log @q.params() if @doEcho
    sql

  compile: ->
    ###
    Compile this query object, returning a SQL string and parameter array.

    :param bindable: (optional)
      If present, the query will be bound to this object using :meth:`bind`
    ###
    [@engine.render(@q), @q.params()]

  execute: (cb) ->
    ###
    Execute the query and buffer all results.

    :param bindable: (optional)
      If present, the query will be bound to this object using :meth:`bind`
    :param cb: A node-style callback that will be called with any errors and/or
      the query results.
    ###
    @engine.execute @, cb

  stream: (cb) ->
    ###
    Execute the query and stream the results.
    
    :param bindable: (optional)
      If present, the query will be bound to this object using :meth:`bind`
    :param cb: A node-style callback that will be called with any errors and/or
      each row of the query results.
 
    ###
    @engine.stream @, cb

  toString: -> @render()

withBinding = (original) ->
  ###
  Decorates a method so that it can accept a bindable object as it's first
  argument, and will always call @bind() before the method itself.
  ###
  (bindable, args...) ->
    unless bindable?.execute or bindable?.connect
      # First argument is not a bindable object
      args.unshift bindable
      bindable = null
    original.apply @bind(bindable), args

for method in ['compile', 'render', 'execute', 'stream']
  BaseQuery::[method] = withBinding BaseQuery::[method]

fluidize BaseQuery, 'bind', 'echo', 'visit'
