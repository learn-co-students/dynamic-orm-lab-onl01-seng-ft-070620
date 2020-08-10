require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
    def self.table_name
        self.to_s.downcase.pluralize
    end
    
    def self.column_names
        DB[:conn].results_as_hash = true
        
        sql = "PRAGMA table_info('#{table_name}')"
        
        table_info = DB[:conn].execute(sql)

        column_names = []
        table_info.each do |row|#iterate over each hash to grab toe name key's value
            column_names << row["name"]
        end
        column_names.compact
    end
    
    #creates new instances with attributes using the hash passed in as an argument
    def initialize(options = {})
        options.each {|property, value| self.send("#{property}=", value)}
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = <<-SQL
          INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
          VALUES (#{self.values_for_insert})
        SQL
    
        DB[:conn].execute(sql)
        self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
    end

    def self.find_by(hash)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{hash.keys.join} = '#{hash.values.join}'")
    end

    def self.find_by(attribute_hash)
        value = attribute_hash.values.first
        formatted_value = value.class == Fixnum ? value : "'#{value}'"
        sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
        DB[:conn].execute(sql)
    end
end