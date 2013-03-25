url      = require('url')
anyDB    = require('any-db')
queries  = require('./queries')
dialects = require('./dialects')

module.exports = -> Engine.create.apply Engine, arguments

class Engine
  ###
  ``Engine`` is gesundheits interface to an actual database.

  Engines have all of the :ref:`query factory functions <query-factories>`
  attached to them as instance methods that automatically bind created queries
  to the engine. They also have these additionaly methods
  ###

  @create = (dbUrl, poolOptions) ->
    ###
    Create an :class:`engine::Engine` instance from an Any-DB_ connect string
    and extra connection pool options, this is exported by gesundheit as
    ``gesundheit.engine(...)``.

    :ref:`This example <engine-usage-example>` shows the most common way to set up
    a single default database engine for an application.

    .. _Any-DB: https://github.com/grncdr/node-any-db
    .. _Any-DB ConnectionPool: https://github.com/grncdr/node-any-db/blob/master/DESIGN.md#connectionpool
    ###
    driverName = url.parse(dbUrl).protocol.replace(':', '').split('+').shift()

    if driverName is 'fake'
      return fakeEngine()

    ctor = dialects[driverName]
    if not ctor?
      throw new Error('no such driver: ' + driverName)
    dialect = new ctor
    pool = anyDB.createPool(dbUrl, poolOptions)
    new Engine driverName, dbUrl, pool, dialect

  constructor: (@driver, @url, @pool, @dialect) ->
    queries.mixinFactoryMethods @

  query: (statement, params, callback) ->
    ###
    Passes arguments directly to the query method of the underlying `Any-DB
    ConnectionPool`_
    ###
    @pool.query(arguments...)

  begin: (callback) ->
    ###
    Start a new transaction and return it.

    The returned object behaves exactly like a new engine, but has ``commit``
    and ``rollback`` methods instead of ``close``. (In fact it's an `Any-DB
    Transaction`_ that has had the query factory functions mixed in to it).

    .. _Any-DB Transaction: https://github.com/grncdr/node-any-db#transaction
    ###
    tx = queries.mixinFactoryMethods(@pool.begin(callback))
    tx.engine = @
    tx.compile = @dialect.compile.bind(@dialect)
    tx

  compile: (root) ->
    ###
    Render an AST to a SQL string and collect parameters
    ###
    @dialect.compile(root)

  close: ->
    ###
    Closes the internal connection pool.
    ###
    @pool.close()

fakeEngine = ->
  ###
  Create a no-op engine that simply returns the compiled SQL and parameter
  array to the result callback. This will be the default until you over-ride
  with ``gesundheit.defaultEngine = myAppEngine``.
  ###
  dialect = new dialects.base
  engine =
    compile: (node) ->
      dialect.compile(node)

    begin: (cb) ->
      if cb then process.nextTick(cb.bind(null, engine))
      engine
    query: (sql, params, cb) ->
      throw new Error("Cannot query with fakeEngine. Do `gesundheit.defaultEngine = gesundheit.engine(url)` before querying")
    close: ->

  return engine
