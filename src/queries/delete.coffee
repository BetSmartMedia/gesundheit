SUDQuery = require './sud'
{Delete} = require '../nodes'

module.exports = class DeleteQuery extends SUDQuery

DeleteQuery.from = (table, opts={}) ->
  opts.table = table
  new DeleteQuery Delete, opts
