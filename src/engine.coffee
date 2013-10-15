url      = require('url')
anyDB    = require('any-db')
queries  = require('./queries/index')
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
    .. _Any-DB ConnectionPool: https://github.com/grncdr/node-any-db/blob/master/API.md#connectionpool
    ###
    parsed = url.parse(dbUrl)
    driverName = parsed.protocol.replace(':', '').split('+').shift()

    if driverName is 'fake'
      pool = fakePool()
      if parsed.protocol.match('pretty')
        dialectType = dialects.pretty
      else
        dialectType = dialects.base
    else
      pool = anyDB.createPool(dbUrl, poolOptions)
      dialectType = dialects[driverName]

    if not dialectType?
      throw new Error('no such dialect: ' + driverName)
    new Engine driverName, dbUrl, pool, new dialectType()

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

    .. _Any-DB Transaction: https://github.com/grncdr/node-any-db/blob/master/API.md#transaction
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

fakePool = ->
  ###
  Create a fake database connection pool that throws errors if you try to
  execute a query.
  ###
  return {
    begin: (cb) ->
      if cb then process.nextTick(cb.bind(null, engine))
      engine
    query: (sql, params, cb) ->
      throw new Error("Cannot query with fakeEngine. Do `gesundheit.defaultEngine = gesundheit.engine(url)` before querying")
    close: ->
  }
