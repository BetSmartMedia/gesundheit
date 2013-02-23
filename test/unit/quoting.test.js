var g = require('../../')
var test = require('tap').test

test('Quoting identifiers', function (t) {
	var baseDialect = new g.dialects.base()
	t.equal('"A \\"very\\" strange table name"',
		baseDialect.quote('A "very" strange table name'),
		"Double quotes are escaped globally")

	t.test('Postgres quotes all identifiers', function (t) {
		var pgDialect = new g.dialects.postgres()
		var projection = g.toProjection('CamelCaseTable.CamelCaseColumn')
		t.equal('"CamelCaseTable"."CamelCaseColumn"', pgDialect.render(projection))
		t.end()
	})
	t.end()
})
