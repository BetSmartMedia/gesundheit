prefixIfNotEmpty = (prefix) ->
  (node) ->
    children = @renderNodeSet node
    if children then prefix + children else ''

exports.BaseDialect = exports.default = class BaseDialect

  render: (node) ->
    type = node.__proto__
    name = type.constructor.name
    until @['render'+name]
      if 'Object' == name or not type
        throw new Error "Couldn't find a renderer for #{node.constructor.name}"
      type = type.__proto__
      name = type.constructor.name
    @['render'+name](node)

  renderString: (s) -> s

  renderNodeSet: (set) ->
    set.nodes.map((n) => @render n).filter((n) -> n).join(set.glue)
   
  renderParenthesizedNodeSet: (set) ->
    "(" + @renderNodeSet(set) + ")"

  renderAlias: (node) ->
    "#{@maybeParens @render node.obj} AS #{@render node.alias}"

  maybeParens: (it) -> if /\s/.exec it then "(#{it})" else it

  renderSelectProjectionSet: (set) ->
    if not set.nodes.length
      '*'
    else
      @renderNodeSet set

  renderProjection: (node) ->
    "#{@quote node.source.ref()}.#{@quote node.field}"

  quote: (part) ->
    if /\./.exec part then "`#{part}`" else part

  renderSqlFunction: (node) -> "#{@render node.name}#{@render node.arglist}"

  renderValueNode: (node) -> node.value

  renderParameter: (node) -> '?'


  renderSelect: prefixIfNotEmpty 'SELECT '
  renderUpdate: prefixIfNotEmpty 'UPDATE '
  renderInsert: prefixIfNotEmpty 'INSERT INTO '
  renderInsertData: prefixIfNotEmpty 'VALUES '
  renderDelete: prefixIfNotEmpty 'DELETE '
  renderUpdateSet: prefixIfNotEmpty 'SET '
  renderRelationSet: prefixIfNotEmpty 'FROM '
  renderWhere: prefixIfNotEmpty 'WHERE '
  renderGroupBy: prefixIfNotEmpty 'GROUP BY '
  renderOrderBySet: prefixIfNotEmpty 'ORDER BY '
  renderReturning: prefixIfNotEmpty 'RETURNING '

  renderLimit: (node) ->
    if node.value then "LIMIT " + node.value else ""

  renderBinary: (node) ->
    @render(node.left) + ' ' + @renderOp(node.op) + ' ' + @render(node.right)

  renderOp: (op) ->
    switch op.toLowerCase()
      when 'ne', '!=', '<>' then '!='
      when 'eq', '='   then '='
      when 'lt', '<'   then '<'
      when 'gt', '>'   then '>'
      when 'lte', '<=' then '<='
      when 'gte', '>=' then '>='
      when 'like' then 'LIKE'
      when 'in' then 'IN'
      when 'is' then 'IS'
      else throw new Error("Unsupported comparison operator: #{op}")
