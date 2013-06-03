returnLastInsertExtension = require('./return_last_insert')

module.exports = (engine) ->
  engine.extendQuery = (query) ->
    if query.constructor.name == 'InsertQuery'
      returnLastInsertExtension(query)

  engine.unextendQuery = (query) ->
    if query.constructor.name == 'InsertQuery'
      returnLastInsertExtension.remove(query)
