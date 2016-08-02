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

class HistoricalQuoteDatabase
  START_DATE = "1950-01-01"
  #START_DATE = "2005-11-01"
  OFF_DAY_FACTOR = 0.6
  HACK_DATE = (Date.today - 60).to_s

  attr_reader :db

  def initialize( datadir )
    @db = KirbyBase.new() { |d|
      d.path = datadir
      d.delay_index_creation = true
    }
  end

  def get_quotes( symbol, dateStart, dateStop, table=nil )
    table = ensure_table( symbol ) if !table
    startStr = date_to_s( dateStart )
    endStr = date_to_s( dateStop )
    table.select_by_date_index { |r|
      r.date >= startStr and r.date <= endStr
    }.sort( -:date )
  end

  def get_quotes_n_days( symbol, days, table=nil )
    table = ensure_table( symbol ) if !table
    endStr = date_to_s( Date.today - (days + (days * OFF_DAY_FACTOR).to_i) )
    #puts "eds =#{endDay} ; #{(days * OFF_DAY_FACTOR).to_i} ; #{days + (days * OFF_DAY_FACTOR).to_i}"
    table.select_by_date_index { |r| 
      r.date >= endStr
    }.sort( -:date )[0..(days-1)]
  end

  def ensure_table( symbol )
    smbl = get_table_symbol( symbol )
    
    if !@db.table_exists?( smbl )
      tbl = @db.create_table( smbl, 
                              :symbol, :String, 
                              :date, { :DataType => :String, :Index => 1 },
                              :open, :Float, :high, :Float, :low, :Float,
                              :close, :Float, :volume, :Integer,
                              :adjClose, :Float, :adjOpen, :Float, 
                              :adjHigh, :Float, :adjLow, :Float, 
                              :dayofweek, :Integer ) 
    else
      tbl = @db.get_table( smbl )
    end

    return tbl
  end

  def ensure_table_quotes( symbol, table )
    hq = table_last_entry( table )
    today = Date.today
#    today = Date.parse( "2005-12-01" )

    if !hq
      load_quotes( symbol, table, Date.parse( START_DATE ), 
                   today, false )
      return table
    end

    if Date.parse( hq.date ) < (today - 1)
      if !load_quotes( symbol, table, Date.parse( hq.date ) + 1, 
                       today, true ) 
        puts "Detected a split/dividend in '#{symbol}'.  Reloading data..."
        # Drop the table. NOTE: Maybe #clear is better/faster?
        @db.drop_table( get_table_symbol( symbol ) )
        # Re-create the table.
        table = ensure_table( symbol )
        # Load fresh data.
        load_quotes( symbol, table, Date.parse( START_DATE ), 
                     today, false )
      end
    end

    table
  end

  private

  def date_to_s( date )
    "#{date.year}-%02d-%02d" % [date.month, date.mday]
  end

  def get_table_symbol( symbol )
    # Some symbols have characters that are not allowed in Ruby Symbols.
    # So replace them with something that is allowed.  Hopefully this won't
    # cause symbol clashing.
    #
    # NOTE: String.to_sym doesn't seem to work. Are ^ . valid Symbol chars?
    nsym = symbol.gsub(/[\^\-\.]/, '_')
    # Add a 'x' character if the symbol begins with a number (like
    # stocks on the HK and China exchanges).
    nsym = "x#{nsym}" if /^[0-9]/ === nsym
    eval( ":#{nsym}" )
    #symbol.to_sym
  end

  #
  # Return the most recent dated entry in the given table.
  #
  def table_last_entry( table )
    # This is a bit of a hack to try to get some speedups.
    ret = table.select_by_date_index { |r| 
      r.date >= HACK_DATE
    }.sort( -:date ).first
    if !ret
      return table.select_by_date_index { |r| true }.sort( -:date ).first
    else
      return ret
    end
  end

  def table_first_entry( table )
    table.select_by_date_index { |r| true }.sort( :date ).first
  end

  #
  # Load quotes between startDate and endDate for the give symbol into
  # the given table.  sd_check should be set to true if Split/Dividend
  # checking is to be performed.
  #
  def load_quotes( symbol, table, startDate, endDate, sd_check=false )
    #puts "load_quotes( #{symbol}, table, #{startDate.to_s}, #{endDate.to_s} )"
    # Retrieve the raw CSV data from yahoofinance.
    YahooFinance.get_historical_quotes( symbol, startDate, endDate ) { |row|

      #puts "#{o="";row.each{|e|o+=e.to_s+","};o}"

      # Do the Split/Dividend check.
      if sd_check
        # If the close != adjClose, there was a split or dividend.
        # We don't insert the rest of the data since the calling method
        # (ensure_table_quotes) is going to drop the table and reload.
        return false if row[4] != row[6]
      end

      # For every row returned from YahooFinance...

      # Fix the date a bit first.
      row[0] = YahooFinance::HistoricalQuote.parse_date( row[0] )
      # Make the values into numbers.
      row[1] = row[1].to_f
      row[2] = row[2].to_f
      row[3] = row[3].to_f
      row[4] = row[4].to_f
      row[5] = row[5].to_i
      row[6] = row[6].to_f

      # Add the adjusted open, high and low values.
      fact = 1 - ( ( row[4] - row[6] ) / row[4] )
      row << row[1] * fact << row[2] * fact << row[3] * fact
      # Add the dayofweek column.
      #
      # Parsing every date is a bit of a performance hit, but this is
      # only done once when retrieving the data from Yahoo and saves
      # time later (when displaying the data).
      row << Date.parse( row[0] ).wday

      # Insert it into the DB.
      table.insert( symbol, *row )
    }
    true
  end
end


if $0 == __FILE__

  require '../grism_prefs'

  def db_startup
    puts "Starting DB..."
    t = Time.now
    #puts "Start   - #{t.to_f}"
    #db = HistoricalQuoteDatabase.new( $PREFS["configdatadir"] )
    db = HistoricalQuoteDatabase.new( "/home/nick/tmp" )
    t2 = Time.now
    puts "DB startup time = #{t2.to_f - t.to_f}"
    db
  end

  def ensure_symbol( db, symbol )
    t = Time.now
    table = db.ensure_table( symbol )
    t2 = Time.now
    db.ensure_table_quotes( symbol, table )
    t3 = Time.now
    puts "#{symbol} - ensure table = #{t2.to_f - t.to_f}; ensure quotes = #{t3.to_f - t2.to_f}"
    table
  end

  def query_n_days( db, symbol, table, days )
    t = Time.now
    recs = db.get_quotes_n_days( symbol, days, table )
#     recs.each do |r|
#       puts "#{r.close},#{r.adjClose},#{r.open},#{(1-((r.close-r.adjClose)/r.close)) * r.open}"
#     end

    t2 = Time.now
    puts "#{symbol} - query time = #{t2.to_f - t.to_f}; recs.size = #{recs.size}"
    table
  end

  $PREFS = GRISM.init_prefs
  GRISM.init_config_dir

  symbol = 'WMT'
  days = 50

#  symbols = %w( WMT IBM YHOO SUNW GOOG AOB CHK DELL HPQ AAPL )
  symbols = [ 'WMT' ]
  db = db_startup
  symbols.each do |sym|
    table = ensure_symbol( db, sym )
    query_n_days( db, sym, table, days )
  end

end
