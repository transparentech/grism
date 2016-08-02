module Mongoose

#-------------------------------------------------------------------------------
# Table class
#-------------------------------------------------------------------------------
class Table
  #-----------------------------------------------------------------------------
  # Table.db
  #-----------------------------------------------------------------------------
  def self.db
    @@db
  end

  #-----------------------------------------------------------------------------
  # Table.db=
  #-----------------------------------------------------------------------------
  def self.db=(db)
    @@db = db
  end

  #-----------------------------------------------------------------------------
  # Table.query
  #-----------------------------------------------------------------------------
  def self.query
    self.db.tables[self][:query]
  end

  #-----------------------------------------------------------------------------
  # Table.table_name
  #-----------------------------------------------------------------------------
  def self.table_name
    self.db.tables[self][:table_name]
  end

  #-----------------------------------------------------------------------------
  # Table.columns
  #-----------------------------------------------------------------------------
  def self.columns
    self.db.tables[self][:columns]
  end

  #-----------------------------------------------------------------------------
  # Table.content_columns
  #-----------------------------------------------------------------------------
  def self.content_columns
    self.db.tables[self][:columns] = self.columns.reject { |c| 
     c.name == :id || c.name =~ /(_id|_count)$/ }
  end

  #-----------------------------------------------------------------------------
  # Table.column_names
  #-----------------------------------------------------------------------------
  def self.column_names
    self.db.tables[self][:columns].collect { |c| c.name }
  end

  #-----------------------------------------------------------------------------
  # Table.path
  #-----------------------------------------------------------------------------
  def self.path
    self.db.path
  end

  #-----------------------------------------------------------------------------
  # Table.plural_form
  #-----------------------------------------------------------------------------
  def self.plural_form(pluralized)
    Util::SINGULAR_TO_PLURAL[Util.class_case_to_us_case(self.to_s)] = pluralized
    Util::PLURAL_TO_SINGULAR[pluralized] = Util.class_case_to_us_case(self.to_s)
  end

  #-----------------------------------------------------------------------------
  # Table.validates_presence_of
  #-----------------------------------------------------------------------------
  def self.validates_presence_of(*col_names)
    define_method(:required?) do |col_name|
      col_names.include?(col_name)
    end
  end

  #-----------------------------------------------------------------------------
  # Table.has_many
  #-----------------------------------------------------------------------------
  def self.has_many(kind)
    table_name = Util.singularize(kind.to_s).to_sym
    class_name = Util.us_case_to_class_case(table_name)
    col = Util.col_name_for_class(self.to_s)

    define_method(kind.to_sym) do 
      klass = Object.const_get(class_name)
      parent_id = @id
      Collection.new(self, klass.find { |r| r.send(col) == parent_id })
    end
  end

  #-----------------------------------------------------------------------------
  # Table.has_one
  #-----------------------------------------------------------------------------
  def self.has_one(kind)
    table_name = kind.to_sym
    class_name = Util.us_case_to_class_case(table_name)
    col = Util.col_name_for_class(self.to_s)

    define_method(kind.to_sym) do
      klass = Object.const_get(class_name)
      parent_id = @id
      klass.find(:first) { |r| r.send(col) == parent_id }
    end
  end

  #-----------------------------------------------------------------------------
  # Table.belongs_to
  #-----------------------------------------------------------------------------
  def self.belongs_to(kind)
    table_name = kind.to_sym
    class_name = Util.us_case_to_class_case(table_name)

    define_method(kind) do
      klass = Object.const_get(class_name.to_s)
      klass.find(send("#{kind}_id".to_sym))
    end

    define_method("#{kind}=".to_sym) do |other|
      other.save
      send("#{kind}_id=".to_sym, other.id.to_i)
      save
    end
  end

  #-----------------------------------------------------------------------------
  # Table.last_id_used
  #-----------------------------------------------------------------------------
  def self.last_id_used
    self.class.read_header[:last_id_used]
  end

  #-----------------------------------------------------------------------------
  # Table.deleted_recs_counter
  #-----------------------------------------------------------------------------
  def self.deleted_recs_counter
    self.class.read_header[:deleted_recs_counter]
  end

  #-----------------------------------------------------------------------------
  # Table.read_header
  #-----------------------------------------------------------------------------
  def self.read_header
    YAML.load(File.open(File.join(self.path, self.table_name.to_s +
     TBL_HDR_EXT), 'rb'))
  end
  
  #-----------------------------------------------------------------------------
  # Table.write_header
  #-----------------------------------------------------------------------------
  def self.write_header(header)
    File.open(File.join(self.path, self.table_name.to_s + TBL_HDR_EXT), 'wb'
     ) { |f| YAML.dump(header, f) }
  end

  #-----------------------------------------------------------------------------
  # Table.init_table
  #-----------------------------------------------------------------------------
  def self.init_table
    tbl_header = self.read_header

    self.read_header[:columns].each do |c| 
      self.init_column(c[:name], c[:data_type], Object.full_const_get(c[:class])
       ) 
    end
  end

  #-----------------------------------------------------------------------------
  # Table.init_column
  #-----------------------------------------------------------------------------
  def self.init_column(col_name, col_def, col_class)
    col = col_class.create(self, col_name, col_def)

    self.columns << col

    (class << self; self; end).class_eval do 
      define_method(col_name) do
        self.columns.detect { |c| c.name == col_name.to_sym }
      end

      define_method("find_by_#{col_name}".to_sym) do |other|
        if col_name == :id
          self.find(other)
        else
          self.find(:first) { |tbl| tbl.send(col_name) == other }
        end
      end

      define_method("find_all_by_#{col_name}".to_sym) do |other, *args|
        self.find(*args) { |tbl| tbl.send(col_name) == other }
      end
    end

    self.class_eval do
      attr_accessor col_name
    end

    col.init_index if col.indexed?
  end

  #-----------------------------------------------------------------------------
  # Table.close
  #-----------------------------------------------------------------------------
  def self.close
    self.columns.each { |c| c.close }
  end

  #-----------------------------------------------------------------------------
  # Table.get_all_recs
  #-----------------------------------------------------------------------------
  def self.get_all_recs
    self.with_table do |fptr|
      begin
        while true
          fpos = fptr.tell
          rec_arr = Marshal.load(fptr)

          yield rec_arr[1..-1], fpos unless rec_arr[0]
        end
      rescue EOFError
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Table.add_column
  #-----------------------------------------------------------------------------
  def self.add_column(col_name, col_def, col_class=Column)
    self.init_column(col_name, col_def, col_class)

    tbl_header = self.read_header

    tbl_header[:columns] << { :name => col_name, :data_type => col_def, 
                          :class => col_class.to_s }

    self.write_header(tbl_header)
  end

  #-----------------------------------------------------------------------------
  # Table.add_indexed
  #-----------------------------------------------------------------------------
  def self.add_indexed_column(col_name, col_def)
    self.add_column(col_name, col_def, SkipListIndexColumn)
  end

  #-----------------------------------------------------------------------------
  # Table.create
  #-----------------------------------------------------------------------------
  def self.create(options={})
    rec = new
    options.each do |k,v|
      rec.send("#{k}=", v) if self.column_names.include? k
    end
    rec.save
    rec
  end

  #-----------------------------------------------------------------------------
  # Table.find
  #-----------------------------------------------------------------------------
  def self.find(*args, &block)
    options = {}
    if args.size == 0
      args = [:all]
    elsif args.first.is_a?(Hash)
      options = args.first
      args = [:all]
    elsif args.first.is_a?(Integer)
      if args.last.is_a?(Hash)
        options = args.last
        args = args[0...-1]
      end
    elsif args.first == :first
      options = args.last if args.last.is_a?(Hash)
      options[:limit] = 1
      args = [:all]
    elsif args.first == :all
      options = args.last if args.last.is_a?(Hash)
    end

    case args.first
      when :all   then self.find_every(options, &block)
      else             self.find_from_ids(args, options)
    end
  end

  #-----------------------------------------------------------------------------
  # Table.find_from_ids
  #-----------------------------------------------------------------------------
  def self.find_from_ids(args, options)
    if args.size == 1
      result = self.get_rec(args.first)
    else
      result = self.apply_options_to_result(args.collect { |a| 
       self.get_rec(a) }, options)
    end
    return result
  end

  #-----------------------------------------------------------------------------
  # Table.find_every
  #-----------------------------------------------------------------------------
  def self.find_every(options, &block)
    # If no block was supplied, just grab all the keys from the id column's
    # index.
    if block
      result = self.find_from_block(&block)
    else
      result = self.id.keys
    end
    return nil if result.nil?

    return self.apply_options_to_result(
     result.collect { |k| self.get_rec(k) }, options)
  end

  #-----------------------------------------------------------------------------
  # Table.find_from_block
  #-----------------------------------------------------------------------------
  def self.find_from_block(&block)
    result = []
    or_result = []
    query = Query.new
    query.find(&block)

    subquery_no = nil
    subquery_type = nil

    # Step through the query block...
    query.predicates.each do |pred|
      # Retain the previous subquery_no and subquery_type.  This will help 
      # determine if I am still in an #any block or just finished an #any block.
      previous_subquery_no = subquery_no
      previous_subquery_type = subquery_type
      subquery_no = pred.subquery_no
      subquery_type = pred.subquery_type

      # If subquery number has not changed, must be in the middle of an #any 
      # block.  Therefore, we are going to do a union of the the comparison's 
      # results to the current or_result.
      if previous_subquery_no == subquery_no
        or_result = or_result | send(pred.property_name).send(pred.comparison, 
         *pred.arg)
      # Otherwise, we are starting either a new :and predicate or a new #any 
      # block.
      else
        # Therefore, the first thing we want to check if the previous subquery 
        #  was an #any block, and add it's result to the overall result array.
        if previous_subquery_type == :or
          # If the previous subquery was an #any block and it was the first
          # subquery in the main query block, initialize the result array
          # to the whole subqquery's result.
          if previous_subquery_no == 1
            result = or_result
          # Otherwise, just do an intersection between the or_result and the 
          # overall result.
          else
            result = result & or_result
          end
        end
        # If the subquery type is :and, then we are just going to add it
        # to the existing result.
        if subquery_type == :and
          # If this is the first subquery, then we just make the overall
          # result equal to the comparison's result
          if subquery_no == 1
            result = send(pred.property_name).send(pred.comparison, *pred.arg) 
          # Otherwise, we are going to do an intersection on the
          # comparison's result and the overall result.
          else
            result = result & send(pred.property_name).send(pred.comparison, 
             *pred.arg)
          end
        # If the subquery type is :or, and it the subquery number is not
        # equal to the previous subquery number, then we know we are 
        # at the first predicate of an #any block and we can initialize the
        # the subquery's result array to whatever the subquery returns.
        else
          or_result = send(pred.property_name).send(pred.comparison, *pred.arg)
        end
      end
    end
    # Now that we are doing executing the whole query, we need to check if
    # the last subquery was an #any block, so that we can make sure the
    # results of this subquery get added into the overall query results.
    if subquery_type == :or
      if subquery_no == 1
        result = or_result
      else
        result = result & or_result
      end
    end

    return result
  end

  #-----------------------------------------------------------------------------
  # Table.apply_options_to_result
  #-----------------------------------------------------------------------------
  def self.apply_options_to_result(result, options)
    return result if result.empty?

    result = self.sort_result(result, *options[:order]) if options.has_key?(
     :order)
    result = result[options[:offset]-1..-1] if options.has_key?(:offset)
    
    if options.has_key?(:limit)
      if options[:limit] == 1
        result = result.first
      else
        result = result[0...options[:limit]]
      end
    end
    return result
  end

  #-----------------------------------------------------------------------------
  # Table.sort_result
  #-----------------------------------------------------------------------------
  def self.sort_result(result, *order)
    sort_cols_arrs = []
    order.each do |sort_col|
      if sort_col.to_s[0..0] == '-'
        sort_cols_arrs << [sort_col.to_s[1..-1].to_sym, :desc]
      elsif sort_col.to_s[0..0] == '+'
        sort_cols_arrs << [sort_col.to_s[1..-1].to_sym, :asc]
      else
        sort_cols_arrs << [sort_col, :asc]
      end
    end

    return result.sort do |a,b|
      x = []
      y = []
      sort_cols_arrs.each do |s|
        if [:integer, :float].include?(send(s.first).data_type)
          a_value = a.send(s.first) || 0
          b_value = b.send(s.first) || 0
        else
          a_value = a.send(s.first)
          b_value = b.send(s.first)
        end
        if s.last == :desc
          x << b_value
          y << a_value
        else
          x << a_value
          y << b_value
        end
      end

      x <=> y
    end
  end

  #-----------------------------------------------------------------------------
  # Table.get_rec
  #-----------------------------------------------------------------------------
  def self.get_rec(id)
    fpos = self.id[id]

    return nil if fpos.nil?
    rec_arr = []

    self.with_table(File::RDONLY) do |fptr|
      fptr.binmode
      fptr.seek(fpos)
      rec_arr = Marshal.load(fptr)
    end      

    raise IndexCorruptError, "Index references deleted record!", caller \
     if rec_arr[0]

    raise IndexCorruptError, "Index ID does not match table ID!", caller \
     unless rec_arr[1] == id

    rec = self.new(Hash[*self.column_names.zip(rec_arr[1..-1]).flatten])
    return rec
  end

  #-----------------------------------------------------------------------------
  # Table.with_table
  #-----------------------------------------------------------------------------
  def self.with_table(access='rb')
    begin
      yield fptr = open(File.join(self.db.path, self.table_name.to_s + TBL_EXT), 
       access)
    ensure
      fptr.close
    end
  end

  #-----------------------------------------------------------------------------
  # Table.export
  #-----------------------------------------------------------------------------
  def self.export(filename=1)
    if filename.is_a?(Integer)
      out_file = IO.open(1, 'wb')
    else
      out_file = File.open(filename, 'wb')
    end
    CSV::Writer.generate(out_file) do |out|
      self.find.each do |rec|
        out << self.column_names.collect {|n| rec.send(n)}
      end
    end

    out_file.close
  end

  #-----------------------------------------------------------------------------
  # Table.import
  #-----------------------------------------------------------------------------
  def self.import(filename=0)
    if filename.is_a?(Integer)
      in_file = IO.open(1, 'rb')
    else
      in_file = File.open(filename, 'rb')
    end

    CSV::Reader.parse(in_file) do |row|
      rec = new
      self.columns.zip(row) do |col, value|
        rec.send("#{col.name}=", col.convert_to_native(value)) unless \
         value.nil?
      end
      rec.save
    end
    in_file.close
  end

  #-----------------------------------------------------------------------------
  # Table.exists?
  #-----------------------------------------------------------------------------
  def self.exists?(id)
    if self.id[id]
      true
    else
      false
    end
  end

  #-----------------------------------------------------------------------------
  # Table.destroy_all
  #-----------------------------------------------------------------------------
  def self.destroy_all(&block)
    self.find(:all, &block).each { |r| p r.destroy }
  end

  #-----------------------------------------------------------------------------
  # Table.destroy
  #-----------------------------------------------------------------------------
  def self.destroy(id)
    self.find(id).destroy
  end

  #-----------------------------------------------------------------------------
  # Table.delete_all
  #-----------------------------------------------------------------------------
  def self.delete_all(&block)
    self.find(:all, &block).each { |r| p r.delete }
  end

  #-----------------------------------------------------------------------------
  # Table.delete
  #-----------------------------------------------------------------------------
  def self.delete(id)
    self.find(id).delete
  end

  #-----------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------
  def initialize(values=nil)
    unless values.nil?
      values.each do |k,v|
        send("#{k}=", v) if self.class.column_names.include? k
      end
    end
  end

  #-----------------------------------------------------------------------------
  # update_attributes
  #-----------------------------------------------------------------------------
  def update_attributes(values)
    values.each do |k,v|
      send("#{k}=", v) if self.class.column_names.include? k
    end
    save
  end

  #-----------------------------------------------------------------------------
  # save
  #-----------------------------------------------------------------------------
  def save
    self.class.columns.each do |c|
      # First checks to see if validates_presence_of was set in class def.
      raise "Value required for #{c.name}!" if respond_to?('required?') and \
       required?(c.name) and send(c.name).nil?
      # Next checks to see if validates_presence_of was set in #add_column.
      raise "Value required for #{c.name}!" if c.required? and send(c.name).nil?
    end

    # Add new record.
    if @id.nil?
      @id = append_record(self.class.column_names[1..-1].collect { |c_name| 
       send(c_name) })
    # Update existing record.
    else
      update_record(@id, self.class.columns[1..-1].collect { |c| send(c.name) })
    end
    return true
  end

  #-----------------------------------------------------------------------------
  # delete
  #-----------------------------------------------------------------------------
  def delete
    destroy
  end

  #-----------------------------------------------------------------------------
  # destroy
  #-----------------------------------------------------------------------------
  def destroy
    fpos_rec_start = self.class.id[@id]

    self.class.with_table(File::RDWR) do |fptr|
      fptr.binmode
      fptr.seek(fpos_rec_start)

      rec = Marshal.load(fptr)
      
      raise IndexCorruptError, "Index ID does not match table ID!", caller \
       unless rec[1] == @id

      # First array position of record is the deleted flag:  true means deleted
      rec[0] = true

      # Record is not actually deleted; it just has its deleted flag set to
      # true.
      write_record(fptr, fpos_rec_start, Marshal.dump(rec))
      increment_deleted_recs_counter
    end

    # Remove all index recs pointing to this record.
    self.class.columns.each_with_index do |c,i|
      if i == 0
        c.remove_index_rec(@id)
      elsif c.indexed?
        c.remove_index_rec(send(c.name), @id)
      end
    end

    # Don't allow any more changes to this record.
    freeze
  end

  #-----------------------------------------------------------------------------
  # Private Methods
  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------
  # append_record
  #-----------------------------------------------------------------------------
  def append_record(values)
    id = increment_last_id_used
    fpos = nil
   
    self.class.with_table(File::RDWR) do |fptr|
      fptr.binmode
      fptr.seek(0, IO::SEEK_END)
      fpos = fptr.tell

      # Append record to end of file, making sure to add deleted flag and record
      # id to front of record.
      fpos = write_record(fptr, 'end', Marshal.dump([false, id].concat(values)))
    end

    # Update indexes with new record.
    self.class.columns.each_with_index do |c,i|
      if i == 0
        c.add_index_rec(id, fpos)
      elsif c.indexed?
        c.add_index_rec(values[i-1], id) unless values[i-1].nil?
      end
    end
    return id
  end

  #-----------------------------------------------------------------------------
  # update_record
  #-----------------------------------------------------------------------------
  def update_record(id, values)
    temp_instance = self.class.get_rec(id)

    fpos_rec_start = self.class.id[id]

    raise(RecordNotFound, 
     "No #{self.class.table_name} record found with id: #{id}") if \
     fpos_rec_start.nil?

    self.class.with_table(File::RDWR) do |fptr|
      fptr.binmode
      fptr.seek(fpos_rec_start)

      old_rec = Marshal.load(fptr)

      new_rec = Marshal.dump(old_rec[0..1].concat(values))
      
      raise IndexCorruptError, "Index ID does not match table ID!", caller \
       unless old_rec[1] == id

      old_rec_length = fptr.tell - fpos_rec_start

      # If updates did not change record length, we can write it back out to
      # the same spot in the file...
      if new_rec.length == old_rec_length
        write_record(fptr, fpos_rec_start, new_rec)
      else
        # Set deleted flag to true and update old rec position.  Increment
        # deleted records counter.
        old_rec[0] = true
        write_record(fptr, fpos_rec_start, Marshal.dump(old_rec))
        increment_deleted_recs_counter

        # Append the updated record to the end of the file and update the 
        # record id index.
        fpos = write_record(fptr, 'end', new_rec)
        self.class.columns[0].add_index_rec(id, fpos)
      end  
    end

    # Update all of the indexed columns with the updated record data.
    self.class.columns[1..-1].each do |c| 
      unless temp_instance.send(c.name) == send(c.name)
        if c.indexed? 
          c.remove_index_rec(temp_instance.send(c.name), id)
          c.add_index_rec(send(c.name), id) unless send(c.name).nil?
        end
      end 
    end
  end

  #-----------------------------------------------------------------------------
  # increment_last_id_used
  #-----------------------------------------------------------------------------
  def increment_last_id_used
    tbl_header = self.class.read_header
    tbl_header[:last_id_used] += 1
    self.class.write_header(tbl_header)
    return tbl_header[:last_id_used]
  end

  #-----------------------------------------------------------------------------
  # increment_deleted_recs_counter
  #-----------------------------------------------------------------------------
  def increment_deleted_recs_counter
    tbl_header = self.class.read_header
    tbl_header[:deleted_recs_counter] += 1
    self.class.write_header(tbl_header)
    return tbl_header[:deleted_recs_counter]
  end

  #-----------------------------------------------------------------------------
  # write_record
  #-----------------------------------------------------------------------------
  def write_record(fptr, pos, record)
    if pos == 'end'
      fptr.seek(0, IO::SEEK_END)
    else
      fptr.seek(pos)
    end

    fpos_rec_start = fptr.tell

    fptr.write(record)
    return fpos_rec_start
  end
end


class Collection
  include Enumerable

  def initialize(owner=nil, records=[])
    @owner = owner
    @records = records
  end

  def each
    @records.each { |rec| yield rec }
  end

  def <<(rec)
    col_name = (@owner.class.table_name.to_s + "_id").to_sym
    rec.send("#{col_name}=".to_sym, @owner.instance_eval { @id })
    rec.save
  end

  def append(rec)
    self << rec
  end

  def size
    @records.size
  end
end

end
