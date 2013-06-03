cteExtension = require('./cte')

module.exports = (engine) ->
  engine.extendQuery = (query) ->
    cteExtension(query)

  engine.unextendQuery = (query) ->
    cteExtension.remove(query)
