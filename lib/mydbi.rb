#!/usr/bin/env ruby
#
# A simplified dbi api that uses defaults.
#
# It isn't that the dbi syntax is difficult or too verbose
# but the patterns of getting the last_insert_id for inserts,
# the number of rows modified for updates, and looping over
# the rows from a select are so common that having a single
# shorthand, one that can use default to my local database
# connection is handy.
#
require 'dbi'
require 'yamlrc'

class Mydbi
  VERSION = "1.0.5"
end

$mydbi_db = nil;

$mydbi_config = {
  :default => {
    :name => '',
    :host => 'localhost',
    :username => 'root',
    :password => ''
  }
}.merge(Yamlrc.new(".mydbirc"))

# make a connection, returns the dbh
#
# the top level query and ascii_query commands will work with
# the most recent dbconnection. but if you save the DatabaseHandle
# returned you can still use those methods off of that object.
#
# @db = dbconnect
# @db.query("whatever")
#
def dbconnect(db=nil, host=nil, username=nil, password=nil)
  config = $mydbi_config[:default] 

  # optionally reset the config to a named datasource
  if db.instance_of?(Symbol)
    if $mydbi_config.key?(db)
      config = $mydbi_config[db] 
      db = nil
    else
      throw ArgumentError.new("No database connection named ':#{db}' is configured")
    end
  end

  db =   config[:db] if db.nil?
  host = config[:host] if host.nil?
  username = config[:username] if username.nil?
  password = config[:password] if password.nil?

  $mydbi_db = DBI.connect("DBI:Mysql:#{db}:#{host}", username, password)
end

# see DBI::DatabaseHandle's query
def query(sql,*values)
  return $mydbi_db.query(sql,*values) # TODO this is not passing the block along properly
end

# see DBI::DatabaseHandle's ascii_query
def ascii_query(sql,*values)
  return $mydbi_db.ascii_query(sql,*values)
end

module DBI
  class DatabaseHandle

    # execute a query
    #
    # SELECT:
    #
    # Either the StatementHandle (sth) is returned or if you
    # pass it a block it will iterate across the results
    # yielding the row
    #
    #   sth = query("select * from songs")
    #   puts sth.rows
    #   while( row = sth.fetch )
    #     p row
    #   end
    #   sth.finish
    #
    # or
    #
    #   query("select * from songs") do |row|
    #     p row
    #   end
    #
    # INSERT:
    #
    # Will return the last_insert_id. Warning! If you provide a bulk insert you'll only
    # see get back the id of the first insert (with Mysql 5.0.45-Debian_1ubuntu3-log anyway).
    #
    #   last_insert_id = query("insert into songs values (?,?,?,?)",nil,artist,album,song)
    #   => 1
    #
    #   last_insert_id = query("insert into songs values (?,?,?,?)",nil,artist,album,song)
    #   => 2
    #
    #
    # UPDATE:
    #
    # Will return the affected_rows_count
    #
    #   affected_row_count = query("update songs set artist=? where song_id = ?",new_artist, song_id)
    #   => 1
    #
    # default:
    #
    # returns sth after preparing and executing
    def query(sql,*values)
      case sql
      when /^\s*select/i
        sth = self.prepare(sql)
        sth.execute(*values)
        if block_given?
          while row = sth.fetch do
            yield(row)
          end
          sth.finish
        else
          return sth
        end

      when /^\s*update/i
        return self.do(sql,*values); # returns affected_rows_count
      
      when /^\s*insert/i
        # automatically getting the last_insert id is really only meant
        # to work when inserting a single record. bulk inserts ?!
        rows_inserted = self.do(sql,*values);
        last_id = nil
        sql.squeeze(" ").match(/insert into ([^ ]*) /) # grab the table
        query("select last_insert_id() from #{$1} limit 1"){|row|
          last_id = row[0];
        }
        return last_id

      else # create, drop, truncate, show, ...
        sth = self.prepare(sql)
        sth.execute(*values)
        return sth

      end
    end

    # prints the query results (columns names and values)
    # much like the mysql commandline
    #
    #   +----+---------+---------------------+
    #   | id | song_id | played_at           |
    #   +----+---------+---------------------+
    #   | 3  | 713     | 2007-12-01 00:44:44 |
    #   | 4  | 174     | 2007-12-01 00:44:44 |
    #   +----+---------+---------------------+
    def ascii_query(sql,*values)
      sth = self.query(sql,*values)
      rows = sth.fetch_all
      col_names = sth.column_names
      sth.finish
      DBI::Utils::TableFormatter.ascii(col_names, rows)
    end

  end
end
