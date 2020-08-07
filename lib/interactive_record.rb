require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

# creates a downcased, pluralized table name based on the class name
  def self.table_name
    self.to_s.downcase.pluralize
  end

# returns an array of SQL column names
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{self.table_name}')"
    table_info = DB[:conn].execute(sql) # returns an array of hashes

    column_names = []
    table_info.each do |row| # iterate over each hash and grab the name key's value
      column_names << row["name"]
    end
    column_names.compact
  end

# create new instances with attributes using the hash passed in as an argument
  def initialize(attributes = {})
    attributes.each { |k, v| self.send(("#{k}="), v) }
  end

# get the table name using .table_name
  def table_name_for_insert
    self.class.table_name
  end

# get the column names using .column_names (except for id)
# instead of an array, we want a string
# not ["id", "name", "grade"]
# want "name, grade"
  def col_names_for_insert
    self.class.column_names.delete_if { |c| c == "id"}.join(", ")
  end

# get the instance's attributes to insert as values
# instead of an array, we want a string
# not [ "Sam", "11" ]
# and not " Sam, 11 "
# want " 'Sam', '11' "
  def values_for_insert
    values = []
    self.class.column_names.each do |c|
      values << "'#{send(c)}'" unless send(c).nil?
    end
    values.join(", ")
  end

# save the instance's attributes as a record to the database table
# assign that record's id value as an id attribute to the instance
  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert})
    SQL

    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

# find a specific record based on a given name attribute passed as an argument
  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
  end

# find a specific record based on the column and value passed in as a argument (as a hash)
  def self.find_by(hash)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{hash.keys.join} = '#{hash.values.join}'")
  end

end
