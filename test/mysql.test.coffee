vows = require 'vows'
assert = require 'assert'

dialect = require '../lib/dialects/mysql'

suite = vows.describe('MySQL Dialect')
clauseTest = (condition, exp, clause) ->
	renderValues = clause.renderValues
	delete clause.renderValues
	obj = topic: dialect.renderClause clause, renderValues
	obj["it should be render to #{exp}"] = (got) -> assert.equal got, exp
	context = {}
	context["When I have #{condition}"] = obj
	suite.addBatch context
		
clauseTest "a single clause", "t.x = ?",
	table: "t", field: "x", op: "=", value: "1"

clauseTest "an array of clause", "t.x = ? AND t.y < ?", [
	{table: "t", field: "x", op: "="}
	{table: "t", field: "y", op: "<"}
]

clauseTest "a multi-clause", "(t.x = ? OR t.y < ?)",
	op: "multi", glue: ' OR ', clauses: [
		{table: "t", field: "x", op: "="}
		{table: "t", field: "y", op: "<"}
	]

clauseTest "nested multi-clause", "((t.x = ? AND t.y = ?) OR (t.z = ? OR t.y = ?))",
op: "multi", glue: ' OR ', clauses: [
	{
		op: "multi", glue: ' AND ', clauses: [
			{table: "t", field: "x", op: "="}
			{table: "t", field: "y", op: "="}
		]
	}
	{
		op: "multi", glue: ' OR ', clauses: [
			{table: "t", field: "z", op: "="}
			{table: "t", field: "y", op: "="}
		]
	}
]
clauseTest "a clause with literal values", "t1.x = t2.y",
	table: "t1", field: "x", op: "=",
	value: "t2.y", 
	renderValues: (v) -> v
	
suite.export module
