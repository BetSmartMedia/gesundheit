fluid = require '../fluid'
{toRelation} = require '../nodes'
assert = require 'assert'

withBinding = (original) ->
  ###
  Decorate a method so that it can accept a bindable object as it's first
  argument, and will always call @bind() before the method.
  ###
  (bindable, args...) ->
    unless bindable?.execute or bindable?.connect
      # First argument is not a bindable object
      args.unshift bindable
      bindable = null
    original.apply @bind(bindable), args


module.exports = class BaseQuery
  ###
  The base class for all queries, this is not exported publically or expected
  to be used directly.
  ###
  constructor: (rootNodeType, opts={}) ->
    ###
    :param rootNodeCtor:  Constructor for the root AST Node (e.g. Select)
    :param opts.table: a ``String``, ``Relation``, ``Alias``, or an object
      literal with a single key and value which will be interpreted as an alias
      name and table, respectively.
    :param opts.bind: an :mod:`engine` or connection that the query will be
      bound to. The engine is used to render and/or execute the query. Unbound
      query objects fall back to using ``gesundheit.defaultEngine`` when methods
      that require an engine are called. Also see: :meth:`bind`.
    ###
    @doEcho  = false
    unless opts.autobind is false
      @bind(opts.binding)
    if (table = opts.table)?
      table = toRelation table
    @q = new rootNodeType table

  copy: ->
    ### Instantiate a new query with a deep copy of this ones AST ###
    c = new @constructor ->
    c.q = @q.copy()
    c.engine = @engine
    return c

  visit: fluid (fn) ->
    ###
    Call the given function in the context of this query. This is mostly useful
    in coffeescript where you can use it as a sort-of-DSL::
        
        queryObject.visit ->
          @where x: val
          @orderBy x: 'ASC'
    
    The current query is also given as the first parameter to the query, in
    case you need it.
    ###
    fn.call @, @ if fn?

  echo: fluid ->
    ###
    If called before .toSql(), then resulting SQL will be sent to stdout
    via console.log()
    ###
    @doEcho = true

  bind: fluid (bindable=null) ->
    ###
    Bind this query object to a `bindable` object (engine or connection).
    If ``bindable == null`` the query will be bound to the default engine.
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

  render: withBinding ->
    ### Render the query to SQL. ###
    sql = @engine.render @q
    console.log sql if @doEcho
    console.log @q.params() if @doEcho
    sql

  compile: withBinding ->
    ###
    Compile this query object, returning a SQL string and parameter array.
    :param bindable: (optional)
      The query will *temporarily* be bound to this object using :meth:`bind`
    ###
    [@engine.render(@q), @q.params()]

  execute: withBinding (cb) ->
    ###
    Execute the query and buffer all results.

    :param bindable: (optional)
      If present, the query will be bound to this object using :meth:`bind`
    :param cb: Result callback of the form ``(err, res) -> undefined``
    ###
    @engine.execute @, cb

  stream: withBinding (cb) ->
    ###
    Execute the query and stream the results.
    
    :param bindable: (optional)
      If present, the query will be bound to this object using :meth:`bind`
    :param cb: Per-row callback of the form ``(err, row) -> undefined``
    ###
    @engine.stream @, cb

  toString: -> @render()
