require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        table_info = DB[:conn].execute("PRAGMA table_info('#{table_name}')")
        column_names = []
        table_info.each do |column|
            column_names << column["name"]
        end
        column_names.compact
    end

    def initialize(options={})
        options.each {|k,v| self.send(("#{k}="),v)}
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(', ')
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |column|
            values << "'#{send(column)}'" unless send(column).nil?
        end
        values.join(', ')
    end

    def save 
        # binding.pry
        DB[:conn].execute("INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})")
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
    end

    def self.find_by(hash)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{hash.keys.join} = '#{hash.values.join}'")
    end
end