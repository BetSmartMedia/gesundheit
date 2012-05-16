# Gesundheit - Concise SQL generation in CoffeeScript

Gesundheit generates SQL, it does this using a nice CoffeeScript friendly syntax.

## Install

    npm install gesundheit

## Examples

```coffee
gesundheit = require('../lib')

# SELECT chairs.* FROM chairs

q = select.from('chairs').visit -> # or Select.from, or SELECT.from   
	# SELECT chairs.type, chairs.size FROM chairs
	@fields "type", "size"

	# SELECT ... WHERE chairs.type = ? AND chairs.size < ?
	@where type: 'recliner', weight: {lt: 25}

	# SELECT ..., people.* FROM chairs INNER JOIN people ON people.chair_id = chair.id WHERE ...
	@join "people", on: {chair_id: @rel('chairs').field('id')}

	# SELECT ..., people.name FROM ...
	@fields "name"
	
	# SELECT ... WHERE ... AND people.gender = ?
	@where gender: 'M'

# More concisely:
q = select.from('chairs', ['type', 'size']).where(type: 'recliner', weight: {lt: 25})
q.join("people", on: {chair_id: q.rel('chairs').field('id')}).fields("name").where(gender: 'M')

# Generate the SQL
q.render() # SELECT chairs.type, chairs.size, people.name FROM chairs INNER JOIN people ...

# Execute the query with an engine
# (MySQL and Postgres included, SQLite planned)
engine = gesundheit.engines.fakeEngine
  
q.bind(engine)
q.execute (err, res) ->
	throw err if err?
	# do something with result

# Or set the default engine globally:
gesundheit.defaultEngine = engine

# You can also bind to a client for transaction support
engine.connect (err, client) ->
	client.query('BEGIN')
	# An arbitrary number of queries here
	gesundheit.update.table('chairs', binding: client)
#		.set(size: 'large')
#    .where(weight: gt: 50)
#    .execute (err, res) ->
#			client.query(if err then 'ROLLBACK' else 'COMMIT')


# Table aliasing
# SELECT ArtWTF.* FROM a_real_table_with_twenty_fields AS ArtWTF
q = select.from ArtWTF: "a_real_table_with_twenty_fields"

# Works with joins as well
q = q.join {so: 'some_other'}, on: {hard: q.rel('ArtWTF').field('is_it')}

# Field aliasing
# SELECT t.really_long_field AS 'rlf' FROM long_table AS t
q = select.from(t: 'long_table').field(rlf: 'really_long_field')
```

## Gesundheit is not an ORM

But a pretty decent ORM could be built with it. The recommended approach is to
provide a dialect (or extend an existing one) with render methods that
understand your model and field types.

## TODO

- More testing
- DBMS specific dialects

## License

MIT

## Author

Stephen Sugden <stephen@betsmartmedia.com>
