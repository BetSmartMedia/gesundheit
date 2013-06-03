###
Add support for common table expressions to queries.
###

module.exports = (query) ->
  query.with = (name, cte) ->
    ###
    Usage (example from http://stackoverflow.com/a/3800572/446634)::
    
      select('summary', ['*']).where(rk: 1)
        .with('summary', select {p: 'purchases'}, ['id', 'customer', 'total'], ->
          @fields func('row_number')
          @over partition: ['customer'], order: [{rk: 'total DESC'}])

      WITH summary AS (
          SELECT p.id, p.customer, p.total, ROW_NUMBER()
            OVER(PARTITION BY p.customer ORDER BY p.total DESC) AS rk
            FROM PURCHASES p)
      SELECT s.*
        FROM summary s
       WHERE s.rk = 1
    ###
    (@ctes ?= {})[name] = cte

    query.compile = (args...) ->
      [text, params] = @::compile.apply(@, args)
      unless @ctes
        return [text, params]
      prefix = "WITH \n"
      for alias, cteQuery of @ctes
        [cteText, cteParams] = cteQuery.compile()
        prefix += "#{cteName} AS (#{cteText})\n"
        params.push.apply(params, cteParams)
      [prefix + text, params]

module.exports.remove = (query) ->
  delete query.ctes
  delete query.with
  delete query.compile
