SUDQuery   = require './sud'
returnable = require './returnable'
{Delete}   = require '../nodes'

module.exports = class DeleteQuery extends SUDQuery
  ### Delete queries only add a 'returning' method to ``SUDQuery`` ###
  @rootNode = Delete

  returnable @
