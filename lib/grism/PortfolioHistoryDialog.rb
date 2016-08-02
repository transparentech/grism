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

class PortfolioHistoryTransTypes 
  include GenericStore

  @@columns = [
               [String, 'transname'],
               [String, 'transtype']
              ]

  @@static_types = [
                    ['Buy', 'buy'],
                    ['Sell', 'sell'],
                    ['Deposit', 'deposit'],
                    ['Withdraw', 'withdraw'],
                    ['Dividend', 'dividend'],
                    ['Interest', 'interest'],
                    ['Other', 'other']
                   ]

  attr_reader :liststore

  def initialize()
    @liststore = Gtk::ListStore.new( *get_column_types( @@columns ) )
    init_column_accessors( @@columns )

    @@static_types.each do |ent|
      iter = @liststore.append()
      iter[transname] = ent[0]
      iter[transtype] = ent[1]
    end
  end

  def get_iter( ttype )
    iter = @liststore.iter_first
    return nil if !iter
    begin
      return iter if iter[transtype] == ttype
    end while( iter.next! )
    nil
  end

end


class PortfolioHistoryDialog < GenericDialog

  def initialize( libglade=nil )
    super( 'pfhistdialog', libglade )
    @tt_store = PortfolioHistoryTransTypes.new
    @libglade['pfhistdialog_transtype'].model = @tt_store.liststore
  end

  protected 

  #
  # Returns a hash with the following keys:
  #   :date, :transtype, :amount, :desc, :comment
  #
  def response_ok( args )
    ret = { }
    ret[:date] = sprintf( "%d-%02d-%02d", 
                          *@libglade['pfhistdialog_date'].date )
    ret[:transtype] = 
      @libglade['pfhistdialog_transtype'].active_iter()[@tt_store.transtype]
    ret[:amount] = @libglade['pfhistdialog_amount'].value
    ret[:desc] = @libglade['pfhistdialog_desc'].text
    ret[:comment] = @libglade['pfhistdialog_comment'].buffer.text
    ret
  end

  #
  # Setup the dialog with initial values based on the situation.
  # 
  # args should contain: 
  #  :date
  #  :transtype
  #  :amount
  #  :desc
  #  :comment
  #
  def setup( args )
    set_calendar( args[:date] )
    @libglade['pfhistdialog_transtype'].
      set_active_iter( @tt_store.get_iter( args[:transtype] ) )
    @libglade['pfhistdialog_amount'].value = args[:amount]
    @libglade['pfhistdialog_desc'].text = args[:desc]
    if args[:comment]
      @libglade['pfhistdialog_comment'].buffer.text = args[:comment]
    else
      @libglade['pfhistdialog_comment'].buffer.text = ""
    end
  end

  private

  def set_calendar( date )
    if ( !date )
      date = Date.today
    end
    if ( date.instance_of?( String ) )
      year, month, day = date.split( '-' )
      @libglade['pfhistdialog_date'].select_month( month.to_i, year.to_i )
      @libglade['pfhistdialog_date'].select_day( day.to_i )
    elsif ( date.instance_of?( Time ) )
      @libglade['pfhistdialog_date'].select_month( date.month, date.year )
      @libglade['pfhistdialog_date'].select_day( date.day )
    end
  end

end
