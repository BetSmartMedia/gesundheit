var dialects = require('../../lib/dialects')
var test = require('tap').test

test('Quoting identifiers', function (t) {
	var baseDialect = new dialects.base()
	t.equal('"A \\"very\\" strange table name"',
		baseDialect.quote('A "very" strange table name'),
		"Double quotes are escaped globally")

	t.end()
})
