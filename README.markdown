# Gesundheit - Concise SQL generation in CoffeeScript

Gesundheit generates SQL, it does this using a nice CoffeeScript friendly syntax.

## Install

    npm install gesundheit

## Examples

```coffee
select = require('gesundheit').select

# SELECT chairs.* FROM chairs
q = select.from('chairs').visit -> # or Select.from, or SELECT.from   
	# SELECT chairs.type, chairs.size FROM chairs
	@fields "type", "size"

	# SELECT ... WHERE chairs.type = ? AND chairs.size < ?
	@where type: 'recliner', weight: {lt: 25}

	# SELECT ..., people.* FROM chairs INNER JOIN people ON people.chair_id = chair.id WHERE ...
	@join "people", on: {chair_id: 'chairs.id'}

	# SELECT ..., people.name FROM ...
	@fields "name"
	
	# SELECT ... WHERE ... AND people.gender = ?
	@where gender: 'M'

# More concisely:
q = select.from('chairs', ['type', 'size']).where(type: 'recliner', weight: {lt: 25})
	.join("people", on: {chair_id: 'chairs.id'}).fields("name").where(gender: 'M')

# Generate the SQL
q.toSql() # SELECT chairs.type, chairs.size, people.name FROM chairs INNER JOIN people ...

# Execute the query with a client (must have a `query` method)
client = query: (sql, params, cb) -> cb null, [{col1: "Cool beans"}]

q.execute client, (err, res) ->
	throw err if err?
	# do something with result

# Execute the query with a connection pool (must have an 'acquire' method)
pool = acquire: (cb) -> cb client

q.execute pool, (err, res) ->
	throw err if err?
	# do something with result

# Table aliasing
# SELECT ArtWTF.* FROM a_real_table_with_twenty_fields AS ArtWTF
q = select.from ArtWTF: "a_real_table_with_twenty_fields"

# Works with joins as well
q = q.join {so: 'some_other'}, on: {hard: 'ArtWTF.is_it'}

# Field aliasing
# SELECT t.really_long_field AS 'rlf' FROM long_table AS t
q = select.from(t: 'long_table').field(rlf: 'really_long_field')
```

## Gesundheit is not an ORM

But a pretty decent ORM could be built with it. Take a look at the resolve hooks in the source

## TODO

- Query types other than SELECT :P

## License

MIT

## Author

Stephen Sugden <stephen@betsmarmedia.com>
