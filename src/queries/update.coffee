fluidize = require '../fluid'
SUDQuery = require './sud'
{Update, binaryOp, toField, toParam} = require '../nodes'

module.exports = class UpdateQuery extends SUDQuery
  ###
  The update query is a little underpowered right now, and can only handle
  simple updates of a single table.
  ###
  @rootNode = Update

  set: (data) ->
    ###
    Add fields to the SET portion of this query.

    :param data: An object mapping fields to values. The values will be passed to
      :func:`nodes::toParam` to be converted into bound paramaeters.
    
    ###
    for field, value of data
      @q.updates.addNode binaryOp toField(field), '=', toParam(value)

  setNodes: (nodes...) ->
    ### Directly push one or more nodes into the SET portion of this query ###
    @q.updates.push nodes...

  defaultRel: -> @q.relation

fluidize UpdateQuery, 'set', 'setNodes'
