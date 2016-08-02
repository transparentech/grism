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

module ChartContext

  attr_reader :charts

  def init_chart_context()
#    @params = params
#    @width = @height = 0
    @charts = []
    @c_width = 0
    @c_height = 0
    @fixed_width = 0
    @fixed_height = 0
  end
  def add( chart )
    cw, ch = chart.default_size

    if chart.fixed_width
      @fixed_width += cw
    else
      @c_width = cw if cw > @c_width
    end

    if chart.fixed_height
      @fixed_height += ch
    else
      @c_height += ch
    end

    @charts << { 
      "chart" => chart, 
      "xpercent" => 1.0, 
      "ypercent" => 1.0,
    }

    @charts.each do |data|
      cw, ch = data["chart"].default_size
      data["xpercent"] = (cw.to_f/@c_width)
      data["ypercent"] = (ch.to_f/@c_height)
    end

#     puts "add_chart: #{@c_width}, #{@c_height}"
#     @charts.each do |data|
#       puts "  #{data['xpercent']}, #{data['ypercent']}"
#     end
  end
  def render( width, height )
    x = 0
    y = 0

    lctx = context( width, height )

    render_initialize( x, y, width, height, lctx )

    @charts.each do |data|
      if data["chart"].fixed_width
        w = data["chart"].default_size[0]
      else
        w = (width - @fixed_width) * data["xpercent"]
      end

      if data["chart"].fixed_height
        h = data["chart"].default_size[1]
      else
        h = (height - @fixed_height) * data["ypercent"]
      end

#      puts "{ #{data['chart']}, #{data['xpercent']}, #{data['ypercent']} }"
      data["chart"].render( lctx, 
#                            x + @params.chart_x_border, 
#                            y + @params.chart_y_border,
                            x + data["chart"].params.border_left, 
                            y + data["chart"].params.border_top,
                            calc_width( w, data["chart"] ), 
                            calc_height( h, data["chart"] ) )
      y += h
    end

    render_finalize( lctx )
  end

  def calc_width( canvas_width, chart )
    return canvas_width - chart.params.border_left - chart.params.border_right
  end
  def calc_height( canvas_height, chart )
    return canvas_height - chart.params.border_top - chart.params.border_bottom
  end
end

class PNGChartContext
  include ChartContext

  def initialize( outfile="/tmp/grism.png" )
    init_chart_context()
    @outfile = outfile
  end

  def context( width, height )
    surface = Cairo::ImageSurface.new( Cairo::FORMAT_ARGB32, width, height )
    return Cairo::Context.new( surface )
  end

  def render_initialize( x, y, width, height, ctx )
    # Draw a white background so the image is not transparent.
    ctx.move_to( x, y )
    ctx.rectangle( x, y, width, height )
    ctx.set_source_rgb( 1.0, 1.0, 1.0 )
    ctx.fill
  end

  def render_finalize( ctx )
    ctx.target.write_to_png( @outfile )
    ctx.target.finish
  end
end

class GtkChartContext < Gtk::DrawingArea
  include ChartContext

  def initialize()
    super()

    init_chart_context()

    signal_connect( "expose-event" ) do |widget, event|
      alloc = widget.allocation
      render( alloc.width, alloc.height )
    end

  end

  def context( width, height )
    return window.create_cairo_context
  end

  def render_initialize( x, y, width, height, ctx )
  end
  def render_finalize( ctx )
  end

  def add( chart )
    super( chart )
    redraw_on_allocate = true
    set_size_request( @c_width + @fixed_width, @c_height + @fixed_height )
  end

  def invalidate
    alloc = allocation()
    window.invalidate( Gdk::Rectangle.new( 0, 0, 
                                           alloc.width, alloc.height ), 
                       false )
  end
end

