assert = require 'assert'

# A macro for building up sql tests. Each sub-context will copy the query
exports.newQuery = (subctx) ->
	sql = subctx.sql
	mod = subctx.mod
	msg = subctx.msg || "SQL is correct \"#{sql}\""
	par = subctx.par
	delete subctx.sql
	delete subctx.mod
	delete subctx.msg
	delete subctx.par

	subctx.topic ?= if mod? and mod.length
		(q) -> mod q.copy()
	else if mod?
		(q) -> q.copy().visit mod
	if sql?
		subctx[msg] = (q) -> assert.strictEqual q.toSql(), sql
	if par?
		subctx["Parameters correct: #{par}"] = (q) ->
			assert.deepEqual(q.params(), par)
	subctx
