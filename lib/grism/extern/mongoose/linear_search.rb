module Mongoose

class LinearSearch
  def initialize(col)
    @col = col
  end

  def search_table(&search)
    col_index = nil
    @col.tbl_class.columns.each_with_index do |c,i| 
      if c.name == @col.name
        col_index = i
        break
      end
    end 

    result = []

    @col.tbl_class.with_table do |fptr|
      begin
        while true
          fpos = fptr.tell
          
          rec_arr = Marshal.load(fptr)

          next if rec_arr[0]

          value = rec_arr[col_index+1]

          if search.call(value)
            result << rec_arr[1]
          end
        end
      rescue EOFError
      end
      return result
    end
  end

  def >(other)
    return search_table do |table_value|
      if table_value.nil? 
        false
      else
        table_value > other 
      end
    end
  end

  def >=(other)
    return search_table do |table_value|
      if table_value.nil? 
        false
      else
        table_value >= other 
      end
    end
  end

  def <(other)
    return search_table do |table_value|
      if table_value.nil? 
        false
      else
        table_value < other 
      end
    end
  end

  def <=(other)
    return search_table do |table_value|
      if table_value.nil? 
        false
      else
        table_value <= other 
      end
    end
  end

  def ==(other)
    return search_table do |table_value|
      if table_value.nil? 
        false
      else
        table_value == other 
      end
    end
  end

  def one_of(*other)
    return search_table do |table_value|
      other.include?(table_value)
    end
  end

  def between(search_start, search_end, start_inclusive=false, 
   end_inclusive=false)
    return search_table do |table_value|
      if table_value < search_start
        false
      elsif table_value == search_start and not start_inclusive
        false
      elsif table_value == search_end and not end_inclusive
        false
      elsif table_value > search_end
        false
      else
        true
      end
    end
  end
end

end
