module Mongoose

#-------------------------------------------------------------------------------
# Database class
#-------------------------------------------------------------------------------
class Database
  attr_reader :path, :tables

  #-----------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------
  def initialize(params={})
    @path = params[:path] || './'  

    Table.db = self

    @tables = {}

    Dir.foreach(@path) do |filename|
      next unless File.extname(filename) == TBL_HDR_EXT

      table_name = File.basename(filename, ".*").to_sym
      init_table(table_name)
    end
  end

  #-----------------------------------------------------------------------------
  # close
  #-----------------------------------------------------------------------------
  def close
    @tables.each_key { |tbl_class| tbl_class.close }
  end

  #-----------------------------------------------------------------------------
  # create_table
  #-----------------------------------------------------------------------------
  def create_table(table_name)
    raise "Table already exists!" if table_exists?(table_name)

    class_name = Util.us_case_to_class_case(table_name)

    tbl_header = {}
    tbl_header[:table_name] = table_name
    tbl_header[:class_name] = class_name
    tbl_header[:last_id_used] = 0
    tbl_header[:deleted_recs_counter] = 0
    tbl_header[:columns] = []
    tbl_header[:columns] << { :name => :id, :data_type => :integer, 
                              :class => IDColumn.to_s }

    File.open(File.join(@path, table_name.to_s + TBL_HDR_EXT), 'wb') do |f|
      YAML.dump(tbl_header, f)
    end

    fptr = File.open(File.join(@path, table_name.to_s + TBL_EXT), 'wb')
    fptr.close

    init_table(table_name)

    yield Object.const_get(class_name) if block_given?
  end

  #-----------------------------------------------------------------------------
  # drop_table
  #-----------------------------------------------------------------------------
  def drop_table(table_name)
    class_name = Util.us_case_to_class_case(table_name)

    @tables[Object.const_get(class_name)][:columns].each do |c|
      if c.indexed?
        File.delete(c.index_file_name) if File.exists?(c.index_file_name)
      end
    end

    File.delete(File.join(@path, table_name.to_s + TBL_HDR_EXT))
    File.delete(File.join(@path, table_name.to_s + TBL_EXT)) if \
     File.exists?(File.join(@path, table_name.to_s + TBL_EXT))
    
    @tables.delete(Object.const_get(class_name))
  end

  #-----------------------------------------------------------------------------
  # table_exists?
  #-----------------------------------------------------------------------------
  def table_exists?(table_name)
    return File.exists?(File.join(@path, table_name.to_s + TBL_HDR_EXT))
  end

  private

  #-----------------------------------------------------------------------------
  # init_table
  #-----------------------------------------------------------------------------
  def init_table(table_name)
    class_name = Util.us_case_to_class_case(table_name)

    @tables[Object.full_const_get(class_name)] = { :class_name => class_name, 
     :table_name => table_name, :columns => [], :query => [] }

    Object.full_const_get(class_name).init_table
  end
end

end
