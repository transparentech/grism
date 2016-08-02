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
class GraphData

  attr_reader :name, :raw
  attr_reader :start_date, :end_date
  attr_reader :x_dates, :x_type
  attr_reader :min_bound, :max_bound
  attr_reader :y_steps, :y_delta

  def init_data( name, data )
    @name = name
    @raw = data

    return if !@raw
    return if @raw.size < 1

    variables_init

    @start_date = @raw.first.date
    @end_date = @raw.last.date
    @x_dates = []

    sd = Date.parse( @raw.first.date )
    @x_type = Charting.x_type( @raw.size, sd, Date.parse( @raw.last.date ) )[1]
    xtmp = sd.mon
    xtmp = sd.year if @x_type > Charting::QUARTER2
    xctr = 1
    ct = 0
    ldate = Charting.date_to_ary( raw.first.date ) << raw.first.dayofweek

    @raw.each do |hq|
      variables_calculate hq

      td, xctr, xtmp, ldate = Charting.x_date( hq.date, hq.dayofweek, ldate, 
                                               @x_type, xctr, xtmp )
      @x_dates << { 'date' => td, 'count' => ct } if td
      ct += 1
    end

    variables_finalize

    @min_bound, @max_bound, @y_steps, @y_delta = 
      Charting.y_bounds( @min_bound.floor, @max_bound.ceil, y_step_quantity )

  end

  def size
    @raw.size
  end
  def first_raw
    @raw.first
  end
  def each_raw
    @raw.each { |r| yield r }
  end
  def legend
    "#{@name}"
  end

  def to_s
    str = "#{@name} [#{self.class.name}] {\n"
    str += "  #{@start_date}, #{end_date}\n"
    str += "  #{o='[';@x_dates.each { |d| o<<'{'<<d['date']<<','<<d['count'].to_s<<'}' };o<<']';o}\n"
    str += "  #{@y_steps}, #{@y_delta}\n"
    str += "  #{@min_bound}, #{max_bound}\n"
    str += variables_to_s + "\n"
    str += "}"
  end

  private


end

class PriceData < GraphData

  attr_reader :max_absolute, :min_absolute
  attr_reader :max_close, :min_close

  def initialize( name, data )
    init_data( name, data )
  end

  def each
    @raw.each { |r| yield close( r ) }
  end

  def []( i )
    close( @raw[i] )
  end

  def first
    close( @raw.first )
  end

  def range_legend
    "Range: #{@min_close} - #{@max_close}"
  end
    
  protected 

  def variables_init
    # This might be useful later.
    # @min_absolute = @raw[0].low
    # @max_absolute = @raw[0].high

    @min_absolute = close( @raw[0] )
    @max_absolute = close( @raw[0] )

    @min_close = close( @raw[0] )
    @max_close = 0
  end
  def variables_calculate( hq )
    # This might be useful later.
    # @min_absolute = hq.low if @min_absolute > hq.low
    # @max_absolute = hq.high if @max_absolute < hq.high
    
    @min_absolute = close( hq ) if @min_absolute > close( hq )
    @max_absolute = close( hq ) if @max_absolute < close( hq )

    @min_close = close( hq ) if @min_close > close( hq )
    @max_close = close( hq ) if @max_close < close( hq )
  end
  def variables_finalize
    @min_bound = @min_absolute
    @max_bound = @max_absolute
  end
  def variables_to_s
    str = "  #{@min_absolute}, #{max_absolute}\n"
    str += "  #{@min_close}, #{max_close}"
  end
  def y_step_quantity
    Charting::YQUANTITY_STANDARD
  end

  private

  def close( hq )
    # Change this if you're thinking of storing the adjusted values.
    #hq.close
    hq.adjClose
  end

#   def each_day
#     @data.each do |hq|
#       yield hq.close, hq.high, hq.low, hq.open, hq.volume
#     end
#   end
#   def each_week
#     #yield close, high, low, open, volume
#   end

end
class VolumeData < GraphData

  attr_reader :max_volume, :min_volume

  def initialize( name, data )
    init_data( name, data )
  end

  def each
    @raw.each { |r| yield r.volume }
  end

  def []( i )
    @raw[i].volume
  end

  def first
    @raw.first.volume
  end

  def legend
    yt, ytl = Charting.y_label_type( @y_delta )
    "Volume#{ytl ? " #{ytl}" : ''}"
  end

  def range_legend
    "Range: #{@min_volume} - #{@max_volume}"
  end

  protected 

  def variables_init
    @min_volume = @raw[0].volume
    @max_volume = 0
  end
  def variables_calculate( hq )
    @min_volume = hq.volume if @min_volume > hq.volume
    @max_volume = hq.volume if @max_volume < hq.volume
  end
  def variables_finalize
    @min_bound = @min_volume
    @max_bound = @max_volume
  end
  def variables_to_s
    str = "  #{@min_volume}, #{max_volume}"
  end
  def y_step_quantity
    Charting::YQUANTITY_SMALL
  end
end
class MovingAverageData < GraphData
  def variables_init
  end
  def variables_calculate( hq )
  end
  def variables_finalize
  end
  def variables_to_s
  end
end
class BoilingerData < GraphData
  def variables_init
  end
  def variables_calculate( hq )
  end
  def variables_finalize
  end
  def variables_to_s
  end
end


  def GraphData.get_price_data( symbol, sd, ed )
    # $PREFS["db"].get_quotes( symbol, sd, ed ) ).reverse!
    PriceData.new( symbol, data )
  end



if $0 == __FILE__
  require '../extern/yahoofinance'
  symbol = 'ENG'
  quotes = YahooFinance.get_historical_quotes_days( symbol, 200 )
  data = PriceData.new( symbol, quotes )
  puts "#{data.to_s}"
  data = VolumeData.new( symbol, quotes )
  puts "#{data.to_s}"
end
