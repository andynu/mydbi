= mydbi

http://github.com/andynu/mydbi

== DESCRIPTION:

  A simple wrapper for dbi that provides two simple functions,
  and auth profiles via a configuration file.

== FEATURES/PROBLEMS:

* PROBLEM: no tests => I have some, but they point at local databases and I have not gotten around to making nice mocky ones.

== SYNOPSIS:

DISCLAMER: The DBI api is fine and in most contexts should be used directly.
I wrote it as a little helper for the hundreds of tiny csv outputers,
backfills, and other assorted one-off sys-admin data munghing scripts scripts
that I write. This script intoduces three methods into the Object namespace, it
should not be used in a larger project. Please keep that in mind.

A simple wrapper for dbi that provides two simple functions:

  dbconnect(dbname="test", host="localhost", user="root", pass="")
  dbconnect(profile_key)

uses my most common defaults

  query(sql, *values)

which returns the last_insert_id() for auto increment table inserts
and yields row when selecting.

  ascii_query(sql, *values)

select query output much like mysql's commandline client

== Config file $HOME/.mydbirc

A yaml configuration file for named database connections

  ---
  :databaseone:
    :name: db_one
    :host: localhost
    :username: root
    :password:
  :databasetwo:
    :name: db_two
    :host: other_host
    :username: root
    :password: secret

Then you can pass the symbol is as the db name

  db1 = dbconnect(:databaseone)

  db2 = dbconnect(:databasetwo)

== Example:

  require 'mydbi'

  dbconnect(:databaseone)

  lastn_id = query("insert into lastn (id, ord, song_id) values (null, 1, 10)");
  
  query("select * from lastn") do |row|
    puts row.inspect
  end

== Resources

* http://ruby-dbi.rubyforge.org/
* http://www.kitebird.com/articles/ruby-dbi.html

== REQUIREMENTS:

* dbi
* dbd-mysql
* yamlrc

== INSTALL:

(if you haven't already)
> sudo gem install gem_cutter
> gem tumble

> sudo gem install mydbi

== LICENSE:

(The MIT License)

Copyright (c) 2009 Andrew Nutter-Upham

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
