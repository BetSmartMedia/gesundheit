queries = require('./queries')
dialects = require('./dialects')


postgres = (config) ->
  ###
  Create a new Postgres engine using a parameter compatible with
  `https://github.com/brianc/node-postgres/wiki/pg#method-connect <require('pg').connect(config)>`_.

  This will ``require('pg')`` and attempt to use the 'native' interface if it's
  available.
  ###
  pg = require('pg')

  if pg.native
    pg = pg.native

  dialect = new dialects.Postgres

  engine =
    name: "postgres"
    params: config
    render: dialect.render.bind(dialect)
    connect: pg.connect.bind(pg, config)
    destroy: pg.end
  engine.transaction = transaction.bind(engine)
  queries.mixinFactoryMethods(engine)
  engine

mysql = (opts) ->
  ###
  Create a new MySQL engine using an object that is compatible with
  ``require('mysql').create{Connection,Client}(opts)``.

  Additionally, you can specify extra options for ``generic-pool`` by
  including them as an object in ``opts.pool``. The ``create`` and
  ``destroy`` pool functions will be created for you.
  
  This will ``require('mysql-compat')`` which you **must** install separately
  for this function to work.
  ###
  mysql = require('mysql-compat')
  dialect = new dialects.MySQL
  engine =
    name: "mysql"
    params: opts
    render: dialect.render.bind(dialect)
    connect: mysql.connect.bind(null, opts)
    destroy: mysql.end

  engine.transaction = transaction.bind(engine)
  queries.mixinFactoryMethods(engine)
  engine

fakeEngine = ->
  ###
  Create a no-op engine that simply returns the compiled SQL and parameter
  array to the result callback. This will be the default until you over-ride
  with ``gesundheit.defaultEngine = myAppEngine``.
  ###
  bd = new dialects.BaseDialect
  engine =
    params: {}
    render: bd.render.bind(bd)
    connect: (cb) -> cb null, passthroughClient

  passthroughClient =
    engine: engine
    query: (sql, params, cb) ->
      return unless cb
      process.nextTick cb.bind(null, null, [sql, params])

  return engine


transaction = (cb) ->
  @connect (err, conn) =>
    return cb err if err
    tx = createTxProxy.call @, conn
    tx.begin (err) ->
      cb err, tx

createTxProxy = (conn) ->
  proxy =
    connection: conn
    begin: (cb) ->
      conn.pauseDrain()
      conn.query 'BEGIN', (err) ->
        cb(err)
    commit: (cb) ->
      conn.query 'COMMIT', (err) ->
        conn.resumeDrain()
        cb(err)
    rollback: (cb) ->
      conn.query 'ROLLBACK', (err) ->
        conn.resumeDrain()
        cb(err)
    query: conn.query.bind(conn)
    connect: (cb) -> cb null, conn
    render: @render.bind(@)

  queries.mixinFactoryMethods(proxy)
  proxy


module.exports = {mysql, postgres, fakeEngine}
