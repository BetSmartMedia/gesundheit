SUDQuery = require './sud'
{Delete} = require '../nodes'

module.exports = class DeleteQuery extends SUDQuery
  ### Delete queries don't add any new methods to ``SUDQuery`` ###
  @rootNode = Delete
