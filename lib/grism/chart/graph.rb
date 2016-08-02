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

class GraphParams
  attr_accessor :color, :line_width

  def initialize
    @color = Gdk::Color.parse( "royalblue" )
    @line_width = 1.0
  end
end

class Graph

  attr_reader :params
  attr_accessor :data

  def initialize( data=nil, params=nil )
    @data = data

    @params = params
    @params = GraphParams.new if !params
  end

  def set_data( data )
    @data = data
  end

  def render( x, xdelta, y, ymin, yscale, height, ctx )
    return if @data == nil

    ctx.move_to( x, ypt( y, height, @data.first, ymin, yscale ) )

    @data.each do |val|
      ctx.line_to( x, ypt( y, height, val, ymin, yscale ) )
      #puts "#{x},#{ypt( y, height, val, ymin, yscale )}"
      x += xdelta
    end

    ctx.set_source_color( @params.color )
    ctx.set_line_width( @params.line_width )
    ctx.stroke
  end

  protected 

  def ypt( y, height, value, ymin, yscale )
    y + height - ((value - ymin) * yscale)
  end
end

class LineGraph < Graph
end
class BarGraph < Graph
end
class CandleStickGraph < Graph
end
class VolumeGraph < Graph
  def render( x, xdelta, y, ymin, yscale, height, ctx )
    return if @data == nil

    ctx.set_source_color( @params.color )
    ctx.set_line_width( xdelta )

    x += xdelta/2

    for i in 1...@data.size
      ctx.move_to( x, y + height )
      ctx.line_to( x, ypt( y, height, @data[i], ymin, yscale) )
      ctx.stroke
      x += xdelta
    end
#     @data.each do |val|
#       ctx.move_to( x, y + height )
#       ctx.line_to( x, ypt( y, height, val, ymin, yscale) )
#       ctx.stroke
#       x += xdelta
#     end
  end
end

