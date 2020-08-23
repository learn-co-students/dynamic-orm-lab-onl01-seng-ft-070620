require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def initialize(i = {})
    i.each do |name, value|
      self.send("#{name}=", value)
    end
  end
  
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    DB[:conn].results_as_hash = true
    tc = DB[:conn].execute("PRAGMA table_info(#{table_name})")
    cn = []
    tc.each do |col|
      cn << col["name"]
    end
    cn.compact
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.delete_if do |i|
      i == "id"
    end.join(", ")
  end
  
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
    values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end
end