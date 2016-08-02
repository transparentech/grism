#                                 Grism
#             An open source, stock market observation tool
#
# Homepage: http://www.grism.org
#
# Grism is an open source stock market observation tool. It allows you
# to easily track the evolution of stock prices through watchlists,
# portfolios and charts.
#
# Grism uses Yahoo! Finance for its quote data. This means that with
# Grism, you can observe stocks, ETFs, indices and mutual funds from
# every major stock market in the world. All you need is the stock's
# symbol that interests you.
#
# Features:
#
# 1. Watchlists - Monitor the evolution of a stock's price from a
# starting price through the last trade.
#
# 2. Portfolios - See the current gain/loss calculation for a set of stocks.
#
# 3. Charts - View dynamic, historical price charts for monitored stocks.
#
#
# Copyright (c) 2007 Nicholas Rahn <nick at transparentech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

class GrismListStore

  include GenericStore
  include GrismSignal

  attr_reader :liststore
  attr_reader :wplist, :list_type
  attr_reader :list_name, :list_desc
  attr_reader :today_total, :overall_total

  def initialize( wplist, columns )
    @liststore = Gtk::ListStore.new( *get_column_types( columns ) )

    init_column_accessors( columns )

    @wplist = wplist
    @list_type = 'grismliststore'
    @today_total = @overall_total = 0.0

    init_signals( ['name', 'description', 'today', 'overall'] )
  end

  def set_preferences( prefs )
  end

  def get_preferences()
    @wplist.prefs
  end

  def list_type=( t )
    @list_type = t
  end
  def list_name=( n )
    @list_name = n
    @wplist.name = n
    @wplist.save
    call_signal( 'name' )
  end
  def list_desc=( d )
    @list_desc = d
    @wplist.desc = d
    @wplist.save
    call_signal( 'description' )
  end
  def today_total=( t )
    @today_total = t
    call_signal( 'today' )
  end
  def overall_total=( o )
    @overall_total = o
    call_signal( 'overall' )
  end

  def find_symbol( smbl )
    iter = @liststore.iter_first
    return nil if !iter
    begin
      return iter if iter[symbol] == smbl
    end while( iter.next! )
    nil
  end

  def has_symbol?( smbl )
    return find_symbol( smbl ) != nil
  end

  def static_row?( iter )
    false
  end

  def get_action_opts_for_iter( iter )
    GRISM::MENU_STOCK_NO_SELECT_OPTS
  end

#   def load
#     File.open( @filename, "r" ) do |f|
#       f.each_line do |line|
#         # Parse any meta-data (type,name,desc,etc) in the CSV file.
#         if line =~ /^#~\s*(\w+)\s*=\s*(.*)\s*$/
#           instance_eval( "self.#{$1} = \"#{GrismListStore.unprepare_line( $2 )}\"" )
#         end
#         next if line =~ /^#/
#         yield line if block_given?
#       end
#     end
#   end

#   def save( &block )
#     GrismListStore.save_csv_file( @filename, list_type, 
#                             @list_name, @list_desc, &block )
#   end

#   def GrismListStore.prepare_line( line )
#     #puts "prepare_line: #{line.gsub( "\n", "~" )}"
#     return line.gsub( "\n", "~" )
#   end

#   def GrismListStore.unprepare_line( line )
#     #puts "unprepare_line: #{line.gsub( "~", "\n" )}"
#     return line.gsub( "~", "\n" )
#   end

#   def GrismListStore.new_csv_file( type, name, desc, &block )
#     filename = GRISM.get_full_config_file_path( "#{Time.now.to_i}.csv" )
#     save_csv_file( filename, type, name, desc, &block )
#   end

#   def GrismListStore.save_csv_file( filename, type, name, desc )
#     File.open( filename, "w" ) do |f|
#       f.puts( "#~ list_type = #{type}" )
#       f.puts( "#~ list_name = #{name}" )
#       f.puts( "#~ list_desc = #{GrismListStore.prepare_line( desc )}" )
#       yield f if block_given?
#     end
#     filename
#   end

end
