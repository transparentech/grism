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

#
# Data store for watchlists.  This is essentially a Gtk::ListStore
# with some extra features for Grism and watchlists.
#
class WatchListStore < GrismListStore

  @@columns = [
    [String, "symbol"], 
    [String, "name"], 
    [String, "comment"], 
    [String, "date"], 
    [Float, "previousClose"], 
    [Float, "open"], 
    [Float, "lastTrade"], 
    [Float, "change"], 
    [Float, "percent"], 
    [Float, "watchStart"], 
    [Float, "watchChange"], 
    [Float, "watchPercent"], 
    [String, "marketCap"], 
    [Float, "eps"], 
    [Float, "peRatio"], 
    [Float, "pegRatio"], 
    [String, "dividend"], 
    [String, "dividendYield"], 
    [Float, "bookValue"], 
    [Float, "pricePerSales"], 
    [Float, "pricePerBook"], 
    [String, "stockExchange"],
    [TrueClass, "important"], 
    [Gdk::Pixbuf, "importantPix"],
    [Watchlist, "dbrow"]
  ]

  attr_reader :d_ups, :d_evens, :d_downs
  attr_reader :ups, :evens, :downs
  attr_reader :totalSymbols, :dayPercent, :totalPercent

  def initialize( watchlist )
    super( watchlist, @@columns )

    self.list_type = 'watchlist'
    self.list_name = watchlist.name
    self.list_desc = watchlist.desc

    @important_true  = Gdk::Pixbuf.new( $FPATH + GRISM::IMPORTANT_TRUE_ICON_9 )
    @important_false = Gdk::Pixbuf.new( $FPATH + GRISM::IMPORTANT_FALSE_ICON_9 )

    @extDone = false
    @totalSymbols = @ups = @evens = @downs = 0
    @d_ups = @d_evens = @d_downs = 0

    load()
  end

  def get_action_opts_for_iter( iter )
    if !iter
      GRISM::MENU_STOCK_NO_SELECT_OPTS
    else
      GRISM::MENU_STOCK_ON_OPTS
    end
  end

  #
  # Save every entry in the store into the database.
  #
  def save()
    ct = 0
    @liststore.each do |model, path, iter|
      if iter[dbrow]
        ct += 1
        iter[dbrow].pos = ct
        iter[dbrow].save
      end
    end
  end
  #
  # Refresh the current quote data for all rows of the store. The
  # extended/ratio quote data will also be updated if this is the
  # refresh.
  #
  def refresh()
    symbols = watchlist_symbols()

    quotes = YahooFinance::get_standard_quotes( symbols )
    quotes_ex = YahooFinance::get_extended_quotes( symbols ) if !@extDone
    @liststore.each do |model,path,iter|
      refresh_row( iter, quotes[iter[symbol]] )
      refresh_row_extended( iter, quotes_ex[iter[symbol]] ) if !@extDone
      calculate_row( iter )
    end
    @extDone = true
    calculate_total()
  end

  #
  # Add a new entry to the watchlist from the given individual parameters.
  #
  def add_row( sym, dt, ws, cm, imp, getquote=true )
    iter = @liststore.append()
    iter[dbrow] = Watchlist.create( :w_p_list_id => @wplist.id,
                                    :symbol => sym )
    yield iter if block_given?
    set_row( iter, sym, dt, ws, cm, imp, getquote )
    save() if $PREFS["autosave"]
    calculate_total()
  end
  #
  # Add a new entry to the watchlist copying the data from the given iter.
  #
  def add_row_from_iter( iter )
    add_row( iter[symbol], iter[date], iter[watchStart], 
             iter[comment], iter[important] )
  end
  #
  # Modify the data of an existing entry in the portfolio.
  #
  def modify_row( iter, dt, ws, cm, imp, getquote=false )
    set_row( iter, iter[symbol], dt, ws, cm, imp, getquote )
    save_row( iter ) if $PREFS["autosave"]
    calculate_total()
  end
  #
  # Remove an entry from the watchlist, removing it both from the
  # store and from the database.
  #
  def remove_row( iter )
    return if !iter
    # Delete from table.
    iter[dbrow].destroy
    # Remove from store.
    @liststore.remove( iter )
    # Save if required.
    save() if $PREFS["autosave"]
    calculate_total()
  end
  #
  # Set a column of the iter to the given value.
  #
  def set_row_column( path, column, value )
    iter = @liststore.get_iter( path )
    return if !iter
    # Do we really want to prevent 0?
    if value != 0
      iter[column] = value
      save_row( iter ) if $PREFS["autosave"]
      calculate_row( iter )
      calculate_total()
    end
  end
  #
  # Toggle the important marker for the given row.
  # 
  def toggle_important( iter )
    set_row_important( iter, !iter[important] )
    save_row( iter ) if $PREFS["autosave"]
  end
  #
  # Perform a x-for-y stock split.
  #
  def split( iter, x, y, log )
    iter[watchStart] = iter[watchStart] * y/x
    if log
      iter[comment] = 
        "#{iter[comment]}\n#{x}-for-#{y}" +
        " split applied on #{Date.today.to_s}."
    end
    save_row( iter ) if $PREFS["autosave"]
    calculate_row( iter )
    calculate_total()
  end
  #
  # Change the stock symbol to the given newname.
  #
  def rename( iter, newname, log )
    if log
      iter[comment] = 
        "#{iter[comment]}\nSymbol changed from '#{iter[symbol]}' " +
        "to '#{newname}' on #{Date.today.to_s}."
    end
    iter[symbol] = newname
    save_row( iter ) if $PREFS['autosave']
  end

  private

  #
  # Load the data in the database into the store.
  # 
  def load()
    Watchlist.find_all_by_w_p_list_id( @wplist.id,
                                       :order => :pos ).each do |wl|
      iter = @liststore.append()
      iter[dbrow] = wl
      iter[lastTrade] = wl.watchstart
      iter[previousClose] = wl.watchstart
      set_row( iter,
               wl.symbol, wl.adddate.to_s, wl.watchstart, 
               wl.comment, wl.important, false )
    end
  end

  def set_row( iter, sym, dt, ws, cm, imp, getquote )
    iter[symbol] = sym

    iter[date] = dt
    iter[dbrow].adddate = Date.parse( dt )

    iter[watchStart] = ws
    iter[dbrow].watchstart = ws

    iter[comment] = cm
    iter[dbrow].comment = cm

    iter[important] = imp
    iter[dbrow].important = imp
    set_row_important( iter, iter[important] )

    # Refresh the quote data if required.
    refresh_row( iter ) if getquote
    refresh_row_extended( iter ) if getquote
    # Calculate the column values of this row.
    calculate_row( iter )
    return iter
  end
  #
  # Set the important column of the given row to the given value.
  #
  def set_row_important( iter, impval )
    iter[important] = impval
    if iter[important]
      iter[importantPix] = @important_true
    else
      iter[importantPix] = @important_false
    end
  end

  #
  # Refresh the current quote data for a particular row in the store.
  # update_row
  def refresh_row( iter, qt=nil )
    sym = iter[symbol]
    qt = YahooFinance.get_standard_quotes( sym )[sym] if !qt
    iter[name] = qt.name
    iter[open] = qt.open
    iter[previousClose] = qt.previousClose
    iter[lastTrade] = qt.lastTrade
  end
  #
  # Refresh the extended/ratio data for a particular row in the store.
  # update_row_extended
  def refresh_row_extended( iter, qt=nil )
    sym = iter[symbol]
    qt = YahooFinance.get_extended_quotes( sym )[sym] if !qt
    iter[marketCap] = qt.marketCap
    iter[eps] = qt.earningsPerShare
    iter[peRatio] = qt.peRatio
    iter[pegRatio] = qt.pegRatio
    iter[dividend] = qt.dividendPerShare
    iter[dividendYield] = qt.dividendYield
    iter[bookValue] = qt.bookValue
    iter[pricePerSales] = qt.pricePerSales
    iter[pricePerBook] = qt.pricePerBook
    iter[stockExchange] = qt.stockExchange
  end
  #
  # Calculate the column values of the given row.
  #
  def calculate_row( iter )
    iter[change] = iter[lastTrade] - iter[previousClose]
    if iter[previousClose] != 0
      iter[percent] = (iter[change]/iter[previousClose])*100
    else
      iter[percent] = 0
    end
    iter[watchChange] = iter[lastTrade] - iter[watchStart]
    iter[watchPercent] = (iter[watchChange]/iter[watchStart])*100
    iter[peRatio] = iter[lastTrade]/iter[eps] if iter[eps] > 0
  end
  #
  # Calculate the watchlist totals.
  def calculate_total()
    @d_ups = @d_evens = @d_downs = 0
    @ups = @evens = @downs = 0
    dayPercent = totalPercent = 0
    ct = 0
    @liststore.each do |model, path, iter|
      @d_ups += 1 if iter[change] > 0
      @d_evens += 1 if iter[change] == 0
      @d_downs += 1 if iter[change] < 0

      @ups += 1 if iter[watchChange] > 0
      @evens += 1 if iter[watchChange] == 0
      @downs += 1 if iter[watchChange] < 0

      dayPercent += iter[percent]
      totalPercent += iter[watchPercent]
      ct += 1
    end
    @totalSymbols = ct
    self.today_total = dayPercent/@totalSymbols if @totalSymbols > 0
    self.overall_total = totalPercent/@totalSymbols if @totalSymbols > 0
  end
  #
  # Copy the data from the store to the database row and save.
  #
  def save_row( iter )
    iter[dbrow].symbol = iter[symbol]
    iter[dbrow].adddate = Date.parse( iter[date] )
    iter[dbrow].watchstart = iter[watchStart]
    iter[dbrow].comment = iter[comment]
    iter[dbrow].important = iter[important]
    iter[dbrow].save
  end

  # Return an array containing the symbols of the securities contained
  # in this watchlist.
  def watchlist_symbols()
    ret = []
    @wplist.watchlists.each { |row| ret << row.symbol }
    return ret
  end

  def daily_totals_s
    "#{@d_ups} (%.1f%%) up / #{@d_evens} (%.1f%%) even / #{@d_downs} (%.1f%%) down" %
      [(@d_ups.to_f/@totalSymbols * 100), 
       (@d_evens.to_f/@totalSymbols * 100), 
       (@d_downs.to_f/@totalSymbols * 100)]
  end

  def totals_s
    "#{@ups} (%.1f%%) up / #{@evens} (%.1f%%) even / #{@downs} (%.1f%%) down" % 
      [(@ups.to_f/@totalSymbols * 100), 
       (@evens.to_f/@totalSymbols * 100), 
       (@downs.to_f/@totalSymbols * 100)]
  end
end
