module Mongoose

#---------------------------------------------------------------------------
# SkipList Class
#---------------------------------------------------------------------------
class SkipList
  MAX_LEVEL = 31
  OPTIMAL_PROBABILITY = 0.25

  attr_reader :size

  #-----------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------
  def initialize(col)
    @col = col
    @size = 0

    # Create header and footer nodes.
    @footer = FooterNode.new
    @header = HeaderNode.new

    # Point all header.forward references to footer node.
    0.upto(MAX_LEVEL) { |i| @header.forward[i] = @footer }

    # This attribute will hold the actual level of the skip list.
    @level = 0
  end

  #-----------------------------------------------------------------------
  # store
  #-----------------------------------------------------------------------
  #++
  # If key not found, will insert new record, otherwise will update value
  # of existing record.
  #
  def store(search_key, new_value)
    # This array will be used to determine which records need their
    # forward array re-adjusted after a new node is created.
    update = []

    # Start off at the header node.
    x = @header

    # Starting at the current highest level of the skip list, walk from
    # left to right at that level, until you see that the next node's
    # key is greater than the key you are searching for.  When this
    # happend, you want to add the current node you are on to the list
    # of nodes that need to have their forward arrays updated.  Next,
    # you want to drop down a level on the current node and start
    # walking forward again, until you again see that the next node's
    # key is bigger than the search key.  In this way, you are walking
    # through the skip list, constantly moving to the right and moving
    # down, until you reach level 0 and are on the node whose key is
    # either equal to the search key (in which case an update will take
    # place), or the highest key in the list that is still lower than
    # the search key (in which case, you have found the place to do an
    # insert).
    @level.downto(0) do |i|
      while x.forward[i].key < search_key
        x = x.forward[i]
      end
      update[i] = x
    end

    x = x.forward[0]

    # If the search key was found, simply update the value of the node.
    if x.key == search_key
      x.value << new_value unless x.value.include?(new_value)
    # If this is an insert, determine the number of levels it will have
    # using a random number.  This is what keeps the skip list balanced.
    else
      lvl = random_level

      # If the new level is higher than the actual current level, we
      # need to make sure that the header node gets updated at these
      # levels.  Then, we set the actual current level equal to the
      # new level.
      if lvl > @level
        (@level + 1).upto(lvl) { |i| update[i] = @header }
        @level = lvl
      end

      # Create a new node.
      x = Node.new(lvl, search_key, [new_value])

      # Now, we need to update all of the nodes that will be affected
      # by the insertion of the new node.  These are nodes whose
      # forward array either will point to the new node and the new
      # node itself.
      0.upto(lvl) do |i|
        x.forward[i] = update[i].forward[i]
        update[i].forward[i] = x
      end
            
      # Increment the size attribute by one.
      @size += 1
    end
  end

  #-----------------------------------------------------------------------
  # remove
  #-----------------------------------------------------------------------
  def remove(search_key, value)
    update = []

    x = @header

    @level.downto(0) do |i|
      while x.forward[i].key < search_key
        x = x.forward[i]
      end
      update[i] = x
    end

    x = x.forward[0]

    if x.key == search_key
      x.value.delete(value)

      if x.value.empty?
        0.upto(@level) do |i|
          break unless update[i].forward[i] == x
          update[i].forward[i] = x.forward[i]
        end

        while @level > 0 and @header.forward[@level] == @footer 
          @level -= 1
        end

        @size -= 1
      end
    end
  end

  #-----------------------------------------------------------------------
  # search
  #-----------------------------------------------------------------------
  def search(search_key)
    result = []
    x = @header

    @level.downto(0) do |i|
      while x.forward[i].key < search_key
        x = x.forward[i]
      end
    end

    x = x.forward[0]

    return x.value if x.key == search_key
  end

  #-----------------------------------------------------------------------
  # one_of
  #-----------------------------------------------------------------------
  def one_of(*other)
    result = []
    other.each do |o|
      result.concat(search(o))
    end
    return result
  end

  #-----------------------------------------------------------------------
  # ==
  #-----------------------------------------------------------------------
  def ==(other)
    search(other)
  end

  #-----------------------------------------------------------------------
  # >
  #-----------------------------------------------------------------------
  def >(search_key)
    result = []
    x = @header

    @level.downto(0) do |i|
      while x.forward[i].key < search_key
        x = x.forward[i]
      end
    end

    x = x.forward[0]
    x = x.forward[0] if x.key == search_key

    while x != @footer
      result.concat(x.value)
      x = x.forward[0]
    end

    result
  end

  #-----------------------------------------------------------------------
  # >=
  #-----------------------------------------------------------------------
  def >=(search_key)
    result = []
    x = @header

    @level.downto(0) do |i|
      while x.forward[i].key < search_key
        x = x.forward[i]
      end
    end

    x = x.forward[0]

    while x != @footer
      result.concat(x.value)
      x = x.forward[0]
    end

    result
  end

  #-----------------------------------------------------------------------
  # <
  #-----------------------------------------------------------------------
  def <(search_key)
    result = []
    x = @header

    x = x.forward[0]

    while x != @footer and x.key < search_key
      result.concat(x.value)
      x = x.forward[0]
    end

    result
  end
        
  #-----------------------------------------------------------------------
  # <=
  #-----------------------------------------------------------------------
  def <=(search_key)
    result = []
    x = @header

    x = x.forward[0]

    while x != @footer and x.key <= search_key
      result.concat(x.value)
      x = x.forward[0]
    end

    result
  end
        
  #-----------------------------------------------------------------------
  # []
  #-----------------------------------------------------------------------
  def [](search_key)
    search(search_key)
  end

  #-----------------------------------------------------------------------
  # between
  #-----------------------------------------------------------------------
  def between(search_start, search_end, start_inclusive=false, 
   end_inclusive=false)
    result = []
    x = @header

    @level.downto(0) do |i|
      while x.forward[i].key < search_start
        x = x.forward[i]
      end
    end

    x = x.forward[0]
    x = x.forward[0] if x.key == search_start and not start_inclusive

    while x != @footer and x.key < search_end
      result.concat(x.value)
      x = x.forward[0]
    end

    result = result.concat(x.value) if x.key == search_end and end_inclusive
    result
  end

  #-----------------------------------------------------------------------
  # each
  #-----------------------------------------------------------------------
  def each
    x = @header.forward[0]
        
    while x != @footer
      yield x.key, x.value
      x = x.forward[0]
    end
  end

  #-----------------------------------------------------------------------
  # load_from_hash
  #-----------------------------------------------------------------------
  def load_from_hash(sl_hash)
    # Create array to hold last node that was at that level, while working
    # backwards.
    levels = []
    0.upto(MAX_LEVEL) { |i| levels << @footer }

    x = nil
    lvl = nil

    # Loop through keys in reverse order...
    sl_hash.keys.sort.reverse.each do |key|
      lvl, value = sl_hash[key]

      # Update skiplist level to be same as highest level yet found in keys.
      @level = lvl if lvl > @level

      # Create node with values from hash.
      x = Node.new(lvl, key, value)

      # Now, for each level of node, point its forward reference to the last
      # node that occupied that level (remember we are working backwards).
      0.upto(lvl) do |i|
        x.forward[i] = levels[i]
        # Now, we want to make current node the last node that occupied that
        # level.
        levels[i] = x
      end
        
      # Now, make sure that, for now, the header node points to this node, 
      # since it is the lowest node, at least until we read the next hash key.
      0.upto(lvl) { |i| @header.forward[i] = x }
    end    
  end

  #-----------------------------------------------------------------------
  # dump_to_hash
  #-----------------------------------------------------------------------
  def dump_to_hash
    sl_hash = {}

    x = @header.forward[0]
        
    while x != @footer
      sl_hash[x.key] = [x.lvl, x.value]
      x = x.forward[0]
    end

    sl_hash
  end

  #-----------------------------------------------------------------------
  # dump
  #-----------------------------------------------------------------------
  def dump
    File.open(@col.index_file_name + '.dump', 'wb') do |fptr|
      x = @header
      fptr.write("----------------  Header -----------------------------\n")
      x.forward.each_with_index do |f,i|
        fptr.write("**** Forward entry %d ****\n" % i)
        fptr.write("Key: " + f.key.inspect + "\n")
        fptr.write("Value: " + f.value.inspect + "\n") unless \
         f.is_a?(FooterNode)
      end
      fptr.write("----------------  End Header -------------------------\n")

      while not x.forward[0].is_a?(FooterNode)
        x = x.forward[0]
        fptr.write("---------------- Node -------------------------\n")
        fptr.write("Key: " + x.key.inspect + "\n") 
        fptr.write("Value: " + x.value.inspect + "\n")
        fptr.write("Level: " + x.lvl.inspect + "\n")
        x.forward.each_with_index do |f,i|
          fptr.write("**** Forward entry %d ****\n" % i)
          fptr.write("Key: " + f.key.inspect + "\n") 
          fptr.write("Value: " + f.value.inspect + "\n") unless \
           f.is_a?(FooterNode)
        end
        fptr.write("---------------- End Node ---------------------\n")
      end

      fptr.write("--------------------- Footer ---------------------\n")
      fptr.write(x.forward[0].inspect + "\n")
      fptr.write("--------------------- End Footer -----------------\n")
    end     
  end

  #-----------------------------------------------------------------------
  # PRIVATE METHODS
  #-----------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------
  # random_level
  #-----------------------------------------------------------------------
  def random_level
    lvl = 0
    while rand < OPTIMAL_PROBABILITY and lvl < MAX_LEVEL
      lvl += 1
    end
    lvl
  end
end


#---------------------------------------------------------------------------
# HeaderNode Class
#---------------------------------------------------------------------------
class HeaderNode
  attr_accessor :forward
  attr_reader :key

  def initialize
    @forward = []
    @key = HeaderKey.new
  end

  def inspect
    self.class.to_s
  end
end


#---------------------------------------------------------------------------
# HeaderKey Class
#---------------------------------------------------------------------------
class HeaderKey
  def ==(other)
    false
  end
end


#---------------------------------------------------------------------------
# FooterNode Class
#---------------------------------------------------------------------------
class FooterNode
  attr_reader :key

  def initialize
    @key = FooterKey.new
  end

  def inspect
    self.class.to_s
  end
end


#---------------------------------------------------------------------------
# FooterKey Class
#---------------------------------------------------------------------------
class FooterKey
  def inspect
    self.class.to_s
  end

  def <(other)
    false
  end
end


#---------------------------------------------------------------------------
# Node Class
#---------------------------------------------------------------------------
class Node
  attr_accessor :forward, :value
  attr_reader :key, :lvl

  def initialize(lvl, key, value)
    @lvl = lvl
    @forward = []
    @key = key
    @value = value
  end

  def inspect
    self.class.to_s
  end
end

end
