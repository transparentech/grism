require 'yaml'
require 'pp'
require 'forwardable'
require 'time'
require 'date'

begin
  require 'faster_csv'
rescue LoadError
  require 'csv'
end

require 'mongoose/database'
require 'mongoose/table'
require 'mongoose/column'
require 'mongoose/skiplist'
require 'mongoose/linear_search'
require 'mongoose/query'
require 'mongoose/util'
require 'mongoose/error'

#
# :main:Mongoose
# :title:Mongoose Module Documentation
# Mongoose is a library that implements a database management system.  It is
# written in Ruby so it runs anywhere Ruby runs.  It uses Skiplists for its
# indexes, so queries are fast.  It uses Marshal to store its data so data
# retrieval is fast.
#
# Author::    Jamey Cribbs (mailto:jcribbs@netpromi.com)
# Homepage::  http://rubyforge.org/projects/mongoose/
# Copyright:: Copyright (c) 2006 NetPro Technologies, LLC
# License::   Distributed under the same terms as Ruby
#
#
module Mongoose

VERSION = '0.2.5'
DATA_TYPES = [:string, :integer, :float, :time, :date, :datetime, :boolean]
TBL_EXT = '.mgt'
TBL_HDR_EXT = '.mgh'
TBL_IDX_EXT = '.mgi'

end


#-------------------------------------------------------------------------------
# Object
#-------------------------------------------------------------------------------
class Object
  def full_const_get(name)
      list = name.split("::")
      obj = Object
      list.each {|x| obj = obj.const_get(x) }
      obj
  end
end


#-------------------------------------------------------------------------------
# Symbol
#-------------------------------------------------------------------------------
class Symbol
  #-----------------------------------------------------------------------------
  # -@
  #-----------------------------------------------------------------------------
  #
  # This allows you to put a minus sign in front of a field name in order
  # to specify descending sort order.
  def -@
      ("-"+self.to_s).to_sym
  end

  #-----------------------------------------------------------------------------
  # +@
  #-----------------------------------------------------------------------------
  #
  # This allows you to put a plus sign in front of a field name in order
  # to specify ascending sort order.
  def +@
      ("+"+self.to_s).to_sym
  end
end
