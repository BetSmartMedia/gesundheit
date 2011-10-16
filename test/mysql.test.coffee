vows = require 'vows'
assert = require 'assert'

{clauseTestFF, newQuery} = require './macros'

dialect = require '../lib/dialects/mysql'
{DELETE} = require '../lib'

clauseTest = clauseTestFF dialect

vows.describe('MySQL Dialect').addBatch(
	"a simple clause": clauseTest
		output: "t.x = ?"
		clause: table: "t", field: "x", op: "=", value: "1"

	"an array of clauses": clauseTest
		output: "t.x = ? AND t.y < ?"
		clause: [
			{table: "t", field: "x", op: "="}
			{table: "t", field: "y", op: "<"}
		]

	"a multi-clause": clauseTest
		output: "(t.x = ? OR t.y < ?)"
		clause: 
			op: "multi", glue: ' OR ', clauses: [
				{table: "t", field: "x", op: "="}
				{table: "t", field: "y", op: "<"}
			]

	"nested multi-clause": clauseTest
		output: "((t.x = ? AND t.y = ?) OR (t.z = ? OR t.y = ?))"
		clause: 
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

	"a clause with literal values": clauseTest
		output: "t1.x = t2.y"
		clause: 
			table: "t1", field: "x", op: "=",
			value: "t2.y", 
		render: (v) -> v
	
	"When I have a DELETE query": 
		topic: DELETE.from('t1', null, dialect: dialect)

		"and join a second table": newQuery
			mod: -> @join "t2", on: {id: 'blah'}

			"adding an orderBy fails": (q) -> assert.throws (-> q.orderBy x: 'DESC'), Error
			"adding a limit fails": (q) -> assert.throws (-> q.limit 1), Error
		
		"and add an order by": newQuery
			mod: -> @orderBy x: 'DESC'

			"joining a second table fails": (q) -> assert.throws (-> q.join 't2'), Error

).export module
