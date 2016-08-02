module Mongoose

#-------------------------------------------------------------------------------
# BaseColumn class
#-------------------------------------------------------------------------------
class BaseColumn
  attr_reader :name, :data_type, :tbl_class
  attr_writer :required

  private_class_method :new

  extend Forwardable
  def_delegator(:@idx, :>, :>)
  def_delegator(:@idx, :>=, :>=)
  def_delegator(:@idx, :==, :==)
  def_delegator(:@idx, :<, :<)
  def_delegator(:@idx, :<=, :<=)
  def_delegator(:@idx, :between, :between)
  def_delegator(:@idx, :one_of, :one_of)

  #-----------------------------------------------------------------------
  # BaseColumn.valid_data_type?
  #-----------------------------------------------------------------------
  def self.valid_data_type?(data_type)
    DATA_TYPES.include?(data_type)
  end

  #-----------------------------------------------------------------------
  # BaseColumn.create_table
  #-----------------------------------------------------------------------
  def self.create(tbl_class, name, col_def)
    return new(tbl_class, name, col_def)
  end

  #-----------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------
  def initialize(tbl_class, name, col_def)
    @tbl_class = tbl_class
    @name = name
    @data_type = col_def
    @indexed = false
    @required = false
  end

  #-----------------------------------------------------------------------
  # indexed?
  #-----------------------------------------------------------------------
  def indexed?
    @indexed
  end

  #-----------------------------------------------------------------------
  # required?
  #-----------------------------------------------------------------------
  def required?
    @required
  end

  #-----------------------------------------------------------------------
  # close
  #-----------------------------------------------------------------------
  def close
  end

  #-----------------------------------------------------------------------
  # convert_to_native
  #-----------------------------------------------------------------------
  def convert_to_native(value)
    case @data_type
    when :string
      value.to_s
    when :integer
      value.to_i
    when :float
      value.to_f
    when :time
      Time.parse(value)
    when :date
      Date.parse(value)
    when :datetime
      DateTime.parse(value)
    when :boolean
      true if [true, 'true', 1].include?(value)
    end
  end
end  


#-------------------------------------------------------------------------------
# Column class
#-------------------------------------------------------------------------------
class Column < BaseColumn
  #-----------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------
  def initialize(tbl_class, name, col_def)
    super
    @idx = LinearSearch.new(self)
  end
end


#-------------------------------------------------------------------------------
# IndexedColumn class
#-------------------------------------------------------------------------------
class IndexedColumn < BaseColumn
  attr_reader :idx, :index_file_name

  #-----------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------
  def initialize(tbl_class, name, col_def)
    super
    @indexed = true

    @index_file_name = File.join(@tbl_class.db.path, 
     @tbl_class.table_name.to_s + '_' + @name.to_s + TBL_IDX_EXT)
  end

  #-----------------------------------------------------------------------------
  # close
  #-----------------------------------------------------------------------------
  def close
    rebuild_index_file if index_file_out_of_date?
  end 

  #-----------------------------------------------------------------------------
  # init_index
  #-----------------------------------------------------------------------------
  def init_index
    if File.exists?(@index_file_name) and not index_file_out_of_date?
      rebuild_index_from_index_file
    else
      rebuild_index_from_table
    end
  end

  #-----------------------------------------------------------------------------
  # with_index_file
  #-----------------------------------------------------------------------------
  def with_index_file(access='rb')
    begin
      yield fptr = open(@index_file_name, access)
    ensure
      fptr.close
    end
  end

  #-----------------------------------------------------------------------------
  # index_file_out_of_date?
  #-----------------------------------------------------------------------------
  def index_file_out_of_date?
    if not File.exists?(@index_file_name) or (File.mtime(File.join(
     @tbl_class.db.path, @tbl_class.table_name.to_s + TBL_EXT)) > 
     File.mtime(@index_file_name))
      true
    else
      false
    end
  end
end  


#-------------------------------------------------------------------------------
# SkipListIndexColumn class
#-------------------------------------------------------------------------------
class SkipListIndexColumn < IndexedColumn
  #-----------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------
  def initialize(tbl_class, name, col_def)
    @idx = SkipList.new(self)
    super
  end

  #-----------------------------------------------------------------------
  # clear_index
  #-----------------------------------------------------------------------
  def clear_index
    @idx = SkipList.new(self)
  end

  #-----------------------------------------------------------------------
  # rebuild_index_file
  #-----------------------------------------------------------------------
  def rebuild_index_file
    with_index_file('wb') { |fptr| fptr.write(Marshal.dump(@idx.dump_to_hash)) }
  end

  #-----------------------------------------------------------------------
  # rebuild_index_from_table
  #-----------------------------------------------------------------------
  def rebuild_index_from_table
    clear_index
    i = @tbl_class.columns.index(self)

    @tbl_class.get_all_recs do |rec, fpos|
      add_index_rec(rec[i], rec[0]) unless rec[i].nil?
    end
  end

  #-----------------------------------------------------------------------
  # rebuild_index_from_index_file
  #-----------------------------------------------------------------------
  def rebuild_index_from_index_file
    clear_index
    with_index_file { |fptr| @idx.load_from_hash(Marshal.load(fptr)) }
  end

  #-----------------------------------------------------------------------
  # add_index_rec
  #-----------------------------------------------------------------------
  def add_index_rec(key, value)
    @idx.store(key, value)
  end

  #-----------------------------------------------------------------------
  # remove_index_rec
  #-----------------------------------------------------------------------
  def remove_index_rec(key, value)
    @idx.remove(key, value)
  end
end  


#-------------------------------------------------------------------------------
# IDColumn class
#-------------------------------------------------------------------------------
class IDColumn < IndexedColumn
  def_delegator(:@idx, :==, :[])
  def_delegator(:@idx, :[], :[])
  def_delegator(:@idx, :keys, :keys)

  #-----------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------
  def initialize(tbl_class, name, col_def)
    @idx = {}
    super
  end

  #-----------------------------------------------------------------------
  # clear_index
  #-----------------------------------------------------------------------
  def clear_index
    @idx = {}
  end

  #-----------------------------------------------------------------------
  # >
  #-----------------------------------------------------------------------
  def >(other)
    return @idx.keys.select { |k| k > other }
  end

  #-----------------------------------------------------------------------
  # >=
  #-----------------------------------------------------------------------
  def >=(other)
    return @idx.keys.select { |k| k >= other }
  end

  #-----------------------------------------------------------------------
  # <
  #-----------------------------------------------------------------------
  def <(other)
    return @idx.keys.select { |k| k < other }
  end

  #-----------------------------------------------------------------------
  # <=
  #-----------------------------------------------------------------------
  def <=(other)
    return @idx.keys.select { |k| k <= other }
  end

  #-----------------------------------------------------------------------
  # between
  #-----------------------------------------------------------------------
  def between(search_start, search_end, start_inclusive=false, 
   end_inclusive=false)
    return @idx.keys.select do |k| 
      if k == search_start and start_inclusive
        true
      elsif k > search_start and k < search_end
        true
      elsif k == search_end and end_inclusive
        true
      else
        false
      end
    end
  end

  #-----------------------------------------------------------------------
  # one_of
  #-----------------------------------------------------------------------
  def one_of(*other)
    return @idx.keys.select { |k| other.include?(k) }
  end

  #-----------------------------------------------------------------------
  # rebuild_index_file
  #-----------------------------------------------------------------------
  def rebuild_index_file
    with_index_file('wb') { |fptr| fptr.write(Marshal.dump(@idx)) }
  end

  #-----------------------------------------------------------------------
  # rebuild_index_from_table
  #-----------------------------------------------------------------------
  def rebuild_index_from_table
    clear_index
    @tbl_class.get_all_recs { |rec, fpos| add_index_rec(rec[0], fpos) }
  end

  #-----------------------------------------------------------------------
  # rebuild_index_from_index_file
  #-----------------------------------------------------------------------
  def rebuild_index_from_index_file
    clear_index
    with_index_file { |fptr| @idx = Marshal.load(fptr) }
  end

  #-----------------------------------------------------------------------
  # add_index_rec
  #-----------------------------------------------------------------------
  def add_index_rec(id, fpos)
    @idx[id] = fpos
  end

  #-----------------------------------------------------------------------
  # remove_index_rec
  #-----------------------------------------------------------------------
  def remove_index_rec(id)
    @idx.delete(id)
  end
end

end
