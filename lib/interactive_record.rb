require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    results = DB[:conn].execute("pragma table_info('#{table_name}')")
    col_names = []
    results.each do |result|
      col_names << result["name"]
    end
    col_names.compact
  end

  def initialize(args = {})
    args.each do | prop, val |
      self.send("#{prop}=", val)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id" }.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col|
      values << "'#{send(col)}'" unless send(col).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert}
      (#{col_names_for_insert})
      VALUES
      (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(arg)
    key = arg.keys[0].to_s
    val = arg[key.to_sym]
    if val == "0" || val.to_f != 0
      val = val.to_f
    end
    result = DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{key} = '#{val}'")
  end
end
