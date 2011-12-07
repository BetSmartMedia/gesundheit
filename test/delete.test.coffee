vows = require 'vows'
assert = require 'assert'
{newQuery} = require('./macros')

{DELETE} = require('../lib')

vows.describe('DELETE queries').addBatch(
	"When performing a DELETE": newQuery
		topic: -> DELETE.from 't1'
		sql: "DELETE FROM t1"

		"and adding a limit": newQuery
			mod: -> @limit 10
			sql: "DELETE FROM t1 LIMIT 10"
			
			"and adding an order": newQuery
				mod: -> @orderBy age: 'DESC'
				sql: "DELETE FROM t1 ORDER BY t1.age DESC LIMIT 10"

).export(module)
