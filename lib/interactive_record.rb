require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = "pragma table_info('#{table_name}')"
        row = DB[:conn].execute(sql)

        row.collect do |hash|
            hash["name"]
        end
    end

    def initialize (attributes = {})
        attributes.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names[1..-1].join( ", ")
    end

    def values_for_insert
        value_array = []
        self.class.column_names.each do |attr|
            value_array << "'#{self.send(attr)}'" unless self.send(attr).nil?
        end
        value_array.join(", ")
    end

    def save
        sql = <<-SQL
            INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
        SQL
        DB[:conn].execute(sql)
        hash_id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}").flatten.first
        @id = hash_id["last_insert_rowid()"]
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM #{self.table_name} WHERE name = '#{name}'
        SQL
        DB[:conn].execute(sql)
    end

    def self.find_by(hash)
        sql = <<-SQL
            SELECT * FROM #{self.table_name} WHERE #{hash.keys.first.to_s} = '#{hash.values.first}'
        SQL
        DB[:conn].execute(sql)
    end
end