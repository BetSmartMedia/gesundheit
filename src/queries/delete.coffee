SUDQuery = require './sud'
{Delete} = require '../nodes'

module.exports = class DeleteQuery extends SUDQuery
  ### Delete queries only add a 'returning' methods to ``SUDQuery`` ###
  @rootNode = Delete

  returning: (cols...) ->
    @q.addReturning cols
    return @

