# Gesundheit - Concise SQL generation in CoffeeScript

Gesundheit generates SQL, it does this using a nice CoffeeScript friendly syntax.

## Install

    npm install gesundheit

## Examples

    query = require 'gesundheit'

    # SELECT chairs.* FROM chairs
    q = query.from('chairs').visit ->    
      # SELECT chairs.type, chairs.size FROM chairs
      @fields "type", "size"

      # SELECT ... WHERE chairs.type = ? AND chairs.size < ?
      @where type: 'recliner', weight: {lt: 25}

      # SELECT ..., people.* FROM chairs INNER JOIN people ON people.chair_id = chair.id WHERE ...
      @join "people", on: {chair_id: 'chair.id'}

      # SELECT ..., people.name FROM ...
      @fields "name"
      
      # SELECT ... WHERE ... AND people.gender = ?
      @where gender: 'M'

    # Or more concisely:
    q = query.from('chairs', ['type', 'size']).where(type: 'recliner', weight: {lt: 25})
    q.join("people", on: {chair_id: 'chair.id'}).fields("name").where(gender: 'M')

    # Generate the SQL
    q.toSql() # SELECT chairs.type, chairs.size, people.name FROM chairs INNER JOIN people ...

    # Execute the query with a client
    mysql = require 'mysql'
    client = mysql.createClient(...)
    q.execute client, (err, res) ->
      throw err if err?
      # do something with result

    # Execute teh query with a connection pool (must have an 'acquire' method)
    pool = require 'generic-pool'
    db = pool.Pool (...)
    q.execute db, (err, res) ->
      throw err if err?
      # do something with result

    # Table aliasing
    # SELECT ArtWTF.* FROM a_real_table_with_twenty_fields AS ArtWTF
    q = query.from ArtWTF: "a_real_table_with_twenty_fields"
    # Works with joins as well
    q = q.join {so: 'some_other'}, on: {hard: 'ArtWTF.is_it'}

## Gesundheit is not an ORM

But a pretty decent ORM could be built with it. Take a look at the resolve hooks in the source

## TODO

- Query types other than SELECT :P

## License

MIT

## Author

Stephen Sugden <stephen@betsmarmedia.com>
