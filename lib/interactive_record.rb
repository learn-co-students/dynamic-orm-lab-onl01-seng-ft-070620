require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
    def self.table_name
        self.to_s.downcase.pluralize
    end
    
    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "PRAGMA table_info('#{table_name}')"

        col_names = []
        DB[:conn].execute(sql).each do |col|
            col_names << col["name"]
        end
        col_names.compact
    end

    def initialize(options={})
        options.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        val_names = self.col_names_for_insert.split(", ")
        vals = val_names.collect do |col|
            "'#{self.send("#{col}")}'"
        end
        vals.join(", ")
    end

    def save
        DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
 
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{table_name} WHERE name = '#{name}'"

        result = DB[:conn].execute(sql)
    end

    def self.find_by(hash)
        sql = "SELECT * FROM #{table_name} WHERE #{hash.keys.first.to_s} = '#{hash.values.first.to_s}'"

        result = DB[:conn].execute(sql)
    end

    
end