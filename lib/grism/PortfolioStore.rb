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
# Data store for portfolios.  This is essentially a Gtk::ListStore
# with some extra features for Grism and portfolios.
#
class PortfolioStore < GrismListStore

  @@columns = [
    [String, 'symbol'], 
    [String, 'name'],
    [String, 'ptype'],
    [String, 'date'], 
    [Float, 'price'], 
    [Float, 'shares'], 
    [String, 'comment'],
    [Float, 'value'], 
    [Float, 'previousClose'],
    [Float, 'lastTrade'], 
    [Float, 'change'], 
    [Float, 'percent'], 
    [Float, 'valueChange'],
    [Float, 'currentValue'], 
    [Float, 'overallChange'], 
    [Float, 'overallPercent'], 
    [Float, 'overallValueChange'], 
    [Float, 'costs'], 
    [Float, 'overallValueChangeAfterCosts'], 
    [Float, 'costPercent'], 
    [Float, 'overallPercentAfterCosts'], 
    [Portfolio, 'dbrow']
  ]

  @@STATIC_SYMBOLS = [ 'Total', 'Cash' ]

  def initialize( portfolio )
    super( portfolio, @@columns )

    init_signals( ['usecash_changed', 'history_changed'] )

    self.list_type = 'portfolio'
    self.list_name = portfolio.name
    self.list_desc = portfolio.desc

    load()

  end

  def set_preferences( prefs )
    if prefs.has_key?( :usecash )
      if prefs[:usecash]
        add_cash_line()
      else
        remove_cash_line()
      end
      @wplist.prefs[:usecash] = prefs[:usecash]
      call_signal( 'usecash_changed' )
    end
    if prefs.has_key?( :defcosts )
      @wplist.prefs[:defcosts] = prefs[:defcosts]
    end
    @wplist.save
  end

  def static_row?( iter )
    @@STATIC_SYMBOLS.include?( iter[symbol] )
  end

  def get_action_opts_for_iter( iter )
    if !iter or @store.static_row?( iter )
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
  # Refresh the current quote data for all rows of the store.
  #
  def refresh()
    symbols = portfolio_symbols()
    quotes = YahooFinance::get_standard_quotes( symbols.join( ',' ) )
    @liststore.each do |model, path, iter|
      next if static_row?( iter )
      refresh_row( iter, quotes[iter[symbol]] )
      calculate_row( iter )
    end
    calculate_total()
  end

  #
  # Add a new entry to the portfolio from the given individual parameters.
  #
  def add_row( sym, ptype, dt, pr, sh, cs, cm, getquote=true )
    #puts "PS.add_row(#{sym},#{ptype},#{dt},#{pr},#{sh},#{cs},#{cm},#{getquote})"
    # Create a new row in the list store, either before the cash line
    # or before the total line.
    if citer = cash_iter()
      iter = 
        @liststore.insert_before( citer )
    else
      iter = 
        @liststore.insert_before( total_iter() )
    end
    # Create a new row in the database.
    iter[dbrow] = Portfolio.create( :w_p_list_id => @wplist.id,
                                    :symbol => sym )
    # Let someone else work on this iter if necessary.
    yield iter if block_given?

    set_row( iter, sym, ptype, dt, pr, sh, cs, cm, getquote )
    save() if $PREFS['autosave']
    if ( ptype == 'long' )
      ttype = 'buy'
    else
      ttype = 'short'
    end
    # Subtract from cash: (price*shares) + costs
    cash_transfer( ttype, -((pr*sh) + cs), dt, cash_desc( sh, sym, pr, cs ) )
    calculate_total()
  end
  #
  # Add a new entry to the portfolio copying the data from the given iter.
  #
  def add_row_from_iter( iter )
    add_row( iter[symbol], 'buy', iter[date], iter[price], 
             iter[shares], iter[costs], iter[comment] )
  end
  #
  # Modify the data of an existing entry in the portfolio.
  #
  def modify_row( iter, ptype, dt, pr, sh, cs, cm, getquote=false )
    set_row( iter, iter[symbol], ptype, dt, pr, sh, cs, cm, getquote )
    save_row( iter ) if $PREFS['autosave']
    calculate_total()
  end
  #
  # Remove an entry from the portfolio, removing it both from the
  # store and from the database.
  #
  def remove_row( iter, ptype, dt, pr, sh, ct, cm )
    #puts "PS.r_r( iter,#{ptype},#{dt},#{pr},#{sh},#{ct},#{cm} )"
    return if !iter
    if ( ptype == 'long' )
      ttype = 'sell'
    else
      ttype = 'cover'
    end
    # Add to cash: value - costs
    cash_transfer( ttype, (sh * pr) - ct,
                   Date.today.to_s, cash_desc( -sh, iter[symbol], pr, ct ) )

    if ( iter[shares] > sh )
      # Only some of the shares were sold, so subtract those shares
      # and recompute the row.
      #
      iter[shares] = iter[shares] - sh
      calculate_row( iter )
    else
      # All of the shares were sold so remove from the db and store.

      # Delete from table.
      iter[dbrow].destroy
      # Remove from store.
      @liststore.remove( iter )
    end

    save() if $PREFS['autosave']
    calculate_total()
  end
  #
  # Set a column of the path to the given value.
  #
  def set_row_column( path, column, value )
    iter = @liststore.get_iter( path )
    return if !iter
    return if static_row?( iter )
    # Do we really want to prevent 0?
    if value != 0
      iter[column] = value
      save_row( iter ) if $PREFS['autosave']
      calculate_row( iter )
      calculate_total()
    end
  end
  #
  # Perform a x-for-y stock split.
  #
  def split( iter, x, y, log )
    if !static_row?( iter )
      iter[price] = iter[price] * y/x
      iter[shares] = iter[shares] * x/y
      if log
        iter[comment] = 
          "#{iter[comment]}\n#{x}-for-#{y}" +
          " split applied on #{Date.today.to_s}."
      end
      save_row( iter ) if $PREFS['autosave']
      calculate_row( iter )
      calculate_total()
    end
  end
  #
  # Change the stock symbol to the given newname.
  #
  def rename( iter, newname, log )
    if !static_row?( iter )
      if log
        iter[comment] = 
          "#{iter[comment]}\nSymbol changed from '#{iter[symbol]}' " +
          "to '#{newname}' on #{Date.today.to_s}."
      end
      iter[symbol] = newname
      save_row( iter ) if $PREFS['autosave']
    end
  end
  #
  # Perform a cash transfer, either a deposit or withdrawl.
  #
  def cash_transfer( ttype, amount, date, desc, comment=nil )
    #puts "cash_transfer(#{ttype},#{amount},#{date},'#{desc}','#{comment}')"
    log_history_event( ttype, date, amount, desc, comment )

    citer = cash_iter()
    return if !citer
    citer[shares] = citer[shares] + amount
    save_row( citer ) if $PREFS['autosave']
    calculate_row( citer )
    calculate_total()
  end

  # Log this event in the PortfolioHistory table.
  def log_history_event( ttype, date, amount, desc, comment=nil )
    ph_val = PortfolioHistory.create( :w_p_list_id => @wplist.id,
                                      :transtype => ttype,
                                      :transdate => Date.parse( date ),
                                      :amount => amount,
                                      :desc => desc,
                                      :comment => comment,
                                      :typecolumns => { } )
    call_signal( 'history_changed', ph_val )
  end

  def total_row?( iter )
    iter[symbol] == 'Total'
  end
  def cash_row?( iter )
    iter[symbol] == 'Cash'
  end
  def cash()
    cash_iter()[currentValue]
  end

  private

  #
  # Load the data in the database into the store.
  # 
  def load()
    # Add the total line.
    totalIter = @liststore.append()
    totalIter[symbol] = 'Total'
    totalIter[ptype] = 'long'
    totalIter[dbrow] = nil

    # Add an entry for each entry in the DB.
    Portfolio.find_all_by_w_p_list_id( @wplist.id, 
                                       :order => :pos ).each do |pf|
      iter = @liststore.insert_before( totalIter )
      iter[dbrow] = pf
      iter[lastTrade] = pf.buyprice
      iter[previousClose] = pf.buyprice
      set_row( iter, 
               pf.symbol, pf.positiontype, pf.buydate.to_s, pf.buyprice, 
               pf.shares, pf.costs, pf.comment,
               false )
    end

    set_preferences( @wplist.prefs )
    calculate_total
  end
  # Set the data of this row from the given parameters.  If 'getquote'
  # is true, the quote data for this row will be refreshed.
  def set_row( iter, sym, pt, dt, pr, sh, cs, cm, getquote )
    #puts "PS.set_row(iter,#{sym},#{dt},#{pr},#{sh},#{cs},#{cm},#{getquote})"
    iter[symbol] = sym
    
    iter[ptype] = pt
    iter[dbrow].positiontype = pt

    iter[date] = dt
    iter[dbrow].buydate = Date.parse( dt )

    iter[price] = pr
    iter[dbrow].buyprice = pr

    iter[shares] = sh
    iter[dbrow].shares = sh

    iter[costs] = cs
    iter[dbrow].costs = cs

    iter[comment] = cm
    iter[dbrow].comment = cm

    # Refresh the quote data if required.
    refresh_row( iter ) if getquote
    # Calculate the column values of this row.
    calculate_row( iter )
    return iter
  end
  #
  # Refresh the current quote data for a particular row in the store.
  #
  def refresh_row( iter, qt=nil )
    sym = iter[symbol]
    qt = YahooFinance.get_standard_quotes( sym )[sym] if !qt
    iter[lastTrade] = qt.lastTrade
    iter[name] = qt.name
    iter[previousClose] = qt.previousClose
  end
  #
  # Calculate the column values of the given row.  Calculations are
  # slightly different for each type of row (stock, cash, total).
  #
  def calculate_row( iter )
    if cash_row?( iter )
      #
      # Cash calculation.
      #
      iter[value] = iter[price] * iter[shares]
      iter[change] = 0
      iter[percent] = 0
      iter[valueChange] = 0
      iter[currentValue] = iter[price] * iter[shares]
      iter[overallChange] = 0
      iter[overallValueChange] = 0
    elsif total_row?( iter )
      # Total row calculation. Nothing specific. See calculate_total
    else
      #
      # Stocks calculation
      #
      iter[value] = iter[price] * iter[shares]
      # If the stock was added today, the change is based on the
      # buyprice. Otherwise is is based on the previousClose.
      if iter[dbrow].buydate == Date.today
        iter[change] = iter[lastTrade] - iter[price]
      else
        iter[change] = iter[lastTrade] - iter[previousClose]
      end
      if iter[previousClose] != 0
        iter[percent] = (iter[change]/iter[previousClose])*100
        iter[percent] = -iter[percent] if iter[ptype] == 'short'
      else
        iter[percent] = 0
      end
      iter[valueChange] = iter[change] * iter[shares]
      iter[currentValue] = iter[lastTrade] * iter[shares]
      iter[overallChange] = iter[lastTrade] - iter[price]
      iter[overallValueChange] = iter[overallChange] * iter[shares]
    end

    # The overallPercent is a general calculation, but is really only
    # pertinent to stocks and the total.
    if iter[value] != 0
      iter[overallPercent] = (iter[overallValueChange]/iter[value])*100
      iter[overallPercent] = -iter[overallPercent] if iter[ptype] == 'short'
    else
      iter[overallPercent] = 0
    end

    # These are still calculated, but we don't display them anymore.
    iter[overallValueChangeAfterCosts] = iter[overallValueChange] - iter[costs]
    iter[costPercent] = (iter[costs]/iter[overallValueChange])*100
    iter[overallPercentAfterCosts] = 
      (iter[overallValueChangeAfterCosts]/iter[value])*100
  end
  #
  # Calculate the portfolio totals.
  #
  def calculate_total()
    tVal = 0.0
    tCurVal = 0.0
    tCosts = 0
    tYVal = 0.0  # total of yesterday's values
    tTVal = 0.0  # total of today's values
    tOValChange = 0 # total of overall's value changes
    tTValChange = 0 # total of today's value changes
    @liststore.each do |model, path, iter|
      if !total_row?( iter )
        tVal += iter[value]
        tCurVal += iter[currentValue]
        tCosts += iter[costs]
        tYVal += (iter[shares] * iter[previousClose])
        tTVal += (iter[shares] * iter[lastTrade])
        tOValChange += iter[overallValueChange]
        tTValChange += iter[valueChange]
      end
    end
    totalIter = total_iter()
    totalIter[value] = tVal
    totalIter[currentValue] = tCurVal
    totalIter[costs] = tCosts
    totalIter[overallValueChange] = tOValChange
    totalIter[valueChange] = tTValChange
    if tYVal == 0
      totalIter[percent] = 0.0
    else
      # (current value - yesterdays value) / yesterdays value
      totalIter[percent] = ((tTVal - tYVal) / tYVal)*100
    end
    calculate_row( totalIter )
    self.overall_total = totalIter[overallPercent]
    self.today_total = totalIter[percent]
  end
  #
  # Copy the data from the store to the database row and save.
  #
  def save_row( iter )
    iter[dbrow].symbol = iter[symbol]
    iter[dbrow].buydate = Date.parse( iter[date] )
    iter[dbrow].buyprice = iter[price]
    iter[dbrow].shares = iter[shares]
    iter[dbrow].costs = iter[costs]
    iter[dbrow].comment = iter[comment]
    iter[dbrow].save
  end

  def add_cash_line()
    # If the portfolio does not already have a cash line, add one.
    if !cash_iter()
      iter = @liststore.insert_before( total_iter() )
      iter[dbrow] = Portfolio.create( :w_p_list_id => @wplist.id,
                                      :symbol => 'Cash' )
      iter[lastTrade] = 1.0
      iter[previousClose] = 1.0
      set_row( iter, 'Cash', 'long', Date.today.to_s, 1.0, 0, 0, '', false )
      cash_transfer( 'deposit', 0, Date.today.to_s, 'Start cash balance.', 
                     'User preferences modified.' )
      save() if $PREFS['autosave']
    end
    calculate_total()
  end

  def remove_cash_line()
    citer = cash_iter()
    if citer
      val = citer[currentValue]
      # Delete from table.
      citer[dbrow].destroy
      # Remove from store.
      @liststore.remove( citer )
      # Log it.
      cash_transfer( 'withdraw', val, Date.today.to_s, 'End cash balance.',
                     'User preferences modified.' )
    end
    calculate_total()
  end

  # Return an array containing the symbols of the securities contained
  # in this portfolio.
  def portfolio_symbols()
    ret = []
    @wplist.portfolios.each { |row| ret << row.symbol }
    return ret
  end

  def total_iter()
    find_symbol( 'Total' )
  end
  def cash_iter()
    find_symbol( 'Cash' )
  end

  def cash_desc( shares, symbol, price, costs )
    "#{shares} of #{symbol} at #{price}; fees=#{costs}"
  end

  public 

  def to_s()
    ret = ''
    @liststore.each do |model, path, iter|
      ret += "#{iter[symbol]},#{iter[name]},#{iter[date]},#{iter[price]},#{iter[shares]},#{iter[costs]},#{iter[comment]}\n"
    end
    ret
  end
end
