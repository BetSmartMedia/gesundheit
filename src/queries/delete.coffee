SUDQuery = require './sud'
{Delete} = require '../nodes'

module.exports = class DeleteQuery extends SUDQuery
  ### Delete queries don't add any new methods to ``SUDQuery`` ###

DeleteQuery.from = (table, opts={}) ->
  ### Create a new ``DeleteQuery`` that will delete rows from ``table`` ###
  opts.table = table
  q = new DeleteQuery Delete, opts
