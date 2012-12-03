url      = require('url')
anyDB    = require('any-db')
queries  = require('./queries')
dialects = require('./dialects')

module.exports = (dbUrl, poolOptions) ->
  ###
  Create an engine using an `Any-DB <https://github.com/grncdr/node-any-db>`_
  connect string and connection pool options, this is exported by gesundheit
  as ``gesundheit.engine(...)``.

  In addition to the drivers supported by Any-DB, gesundheit includes (and
  defaults to using) a "fake" engine that only renders SQL strings.
  ###
  driverName = url.parse(dbUrl).protocol.replace(':', '').split('+').shift()

  if driverName is 'fake'
    return fakeEngine()

  ctor = dialects[driverName]
  if not ctor?
    console.error('no such driver', driverName)
  dialect = new ctor
  pool = anyDB.createPool(dbUrl, poolOptions)

  queries.mixinFactoryMethods {
    driver: driverName
    url:    dbUrl
    render: dialect.render.bind(dialect)
    query:  pool.query.bind(pool)
    close:  pool.close.bind(pool)
    begin:  (cb) ->
      tx = queries.mixinFactoryMethods(pool.begin(cb))
      tx.engine = @
      tx.render = @render
      tx
  }

fakeEngine = ->
  ###
  Create a no-op engine that simply returns the compiled SQL and parameter
  array to the result callback. This will be the default until you over-ride
  with ``gesundheit.defaultEngine = myAppEngine``.
  ###
  dialect = new dialects.BaseDialect
  engine =
    render: dialect.render.bind(dialect)
    begin: (cb) ->
      if cb then process.nextTick(cb.bind(null, engine))
      engine
    query: (sql, params, cb) ->
      return new EventEmitter
      return unless cb
      process.nextTick cb.bind(null, null, [sql, params])
    close: ->

  return engine
