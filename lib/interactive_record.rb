require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    sql = "PRAGMA table_info('#{self.table_name}');"
    table_info = DB[:conn].execute(sql)
    
    column_names = table_info.map { |column| column['name'] }.compact
  end
  
  def initialize(options={})
    options.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end
  
  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert}
      (#{self.column_names_for_insert})
      VALUES (#{self.values_for_insert});
    SQL

    DB[:conn].execute(sql)
    
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert};")[0][0]
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def column_names_for_insert
    self.class.column_names.delete_if { |column_name| column_name == "id" }.join(", ")
  end
  
  def values_for_insert
    values = []
    
    self.class.column_names.each do |column_name|
      values << "'#{self.send(column_name)}'" unless self.send(column_name).nil?
    end
    
    values.compact.join(", ")
  end

  
  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE name = ?
      LIMIT 1;
    SQL
    
    DB[:conn].execute(sql, name)
  end
  
  def self.format_attributes_for_select(attributes_hash)
    formatted_attributes = attributes_hash.map do |attribute, value|
      value.is_a?(Integer) ? formatted_value = value : formatted_value = "'#{value}'"
      "#{attribute} = #{formatted_value}"
    end
    
    formatted_attributes.join(", ")
  end
  
  def self.find_by(attributes_hash)
    attributes_for_select = format_attributes_for_select(attributes_hash)
    
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE #{attributes_for_select}
      LIMIT 1;
    SQL
    
    DB[:conn].execute(sql)
  end
end