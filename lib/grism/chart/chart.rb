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

require 'grism/chart/db'
require 'grism/chart/charting'
require 'grism/chart/chart_context'
require 'grism/chart/graph'
require 'grism/chart/graph_data'

class ChartParams
  LEGEND_NONE = 0
  LEGEND_TOP = 1
  LEGEND_BOTTOM = 2

  attr_accessor :show_x_label_top, :show_x_label_bottom
  attr_accessor :show_y_label_left, :show_y_label_right
  attr_accessor :legend_position, :show_legend_line
  attr_accessor :range_legend_position

  attr_accessor :outline_width, :outline_color
  attr_accessor :background_color
  attr_accessor :grid_color, :grid_width
  attr_accessor :x_label_font, :x_label_font_size
  attr_accessor :y_label_font, :y_label_font_size
  attr_accessor :legend_font, :legend_font_size, :legend_font_color

  attr_accessor :border_top, :border_bottom, :border_left, :border_right
  attr_accessor :outline_redraw

  attr_accessor :output_file

  def initialize()
    @show_x_label_top = false
    @show_x_label_bottom = true
    @show_y_label_left = true
    @show_y_label_right = true
    @legend_position = ChartParams::LEGEND_TOP
    @show_legend_line = true
    @range_legend_position = ChartParams::LEGEND_TOP

    @outline_width = 2.0
    @outline_color = Gdk::Color.parse( "black" )
    @background_color = Gdk::Color.parse( "white" )
    @grid_color = Gdk::Color.parse( "gray" )
    @grid_width = 1.0
    @x_label_font = "Sans"
    @x_label_font_size = 10
    @y_label_font = "Sans"
    @y_label_font_size = 10
    @legend_font = "Sans"
    @legend_font_size = 11
    @legend_font_color = Gdk::Color.parse( "black" )

    @border_top = 20
    @border_bottom = 20
    @border_left = 30
    @border_right = 30
    @outline_redraw = false

    @output_file = "/tmp/grism.png"
  end

  def to_s
    s = "#{self.class.name} {\n"
    s += "  outline_width='#{@outline_width}'\n"
    s += "  outline_color='#{@outline_color.to_s}'\n"
    s += "}"
  end

  def ChartParams.volume_chart_params
    p = ChartParams.new
    p.show_x_label_top = false
    p.show_x_label_bottom = false
    p.legend_position = LEGEND_BOTTOM
    p.show_legend_line = false
    p.range_legend_position = LEGEND_NONE
    p.legend_font_size = 10
    p.border_top = 0
    p.outline_redraw = true
    return p
  end
end

class Chart

  attr_accessor :params
  attr_accessor :graph

  def initialize( pars=nil )
    @params = pars
    @params = ChartParams.new if !pars

#    @graphs = []

    @graph = nil
  end

  def render( ctx, x, y, width, height )

#    puts "#{self.class.name}.render( #{x},#{y},#{width},#{height} )"

#    calculate
    render_base_chart( x, y, width, height, ctx )

#    if @graphs.size < 1
    if !@graph or !@graph.data
      # "No Data Available!"
      render_no_data( x, y, width, height, ctx )
    else
      render_y( x, y, width, height, ctx )
      render_x( x, y, width, height, ctx )
      render_graphs( x, y, width, height, ctx )
      render_legend( x, y, width, height, ctx )
    end

    if @params.outline_redraw
      render_base_chart( x, y, width, height, ctx, true )
    end

  end

  def set_graph( graph )
    @graph = graph
  end

#   def add( graph, graph_data )
#     # need to check date compatability?
#     # chuck out any that don't have same # of pts as others?

#     @principle_data = graph_data if !@principle_data
#     @principle_graph = graph if !@principle_graph

#     @graphs << { "graph" => graph, "data" => graph_data }
#   end

  def default_size
    [400, 200]
  end
  def fixed_height
    false
  end
  def fixed_width
    false
  end

  protected

#   def calculate
#     return if @graphs.size < 1

# #    @y_min = @graphs[0]["data"].min_bound
# #    @y_max = @graphs[0]["data"].max_bound

#     @graphs.each do |g|
#       # calculate the y_min and y_max of all graphs.

#       # but we then assume that all graphs are in the same "range" (ie
#       # not comparing goog with sunw on a price chart).  should have a
#       # percentage chart for disparate ranges (ie compare goog with
#       # sunw on a percentage change basis).

#       # also need to worry about graphs that have different start/end dates.
#       # maybe here is not the best place to look for that....

#       # For the moment we assume 1 graph only.
#     end

# #    @y_min, @y_max, @y_steps, @y_delta = 
# #      Charting.y_bounds( @y_min.floor, @y_max.ceil, y_step_quantity )

# #    puts "#{self.class.name}.calculate #{@y_min},#{@y_max},#{@y_steps},#{@y_delta}"
#   end

  def x_delta( width )
    width / (@graph.data.size - 1.0)
  end
  def y_scale( height )
    height / (@graph.data.max_bound - @graph.data.min_bound).to_f
  end

  #
  # Render the "No Data Available!" in the chart.
  #
  def render_no_data( x, y, width, height, ctx )
    ctx.select_font_face( @params.legend_font,
                          Cairo::FONT_SLANT_NORMAL,
                          Cairo::FONT_WEIGHT_NORMAL )
    ctx.set_font_size( @params.legend_font_size )
    txt = "No Data Available!"
    ext = ctx.text_extents( txt )
    return unless ext

    xtext = width / 2 - ext.width / 2
    ytext = height / 2 + ext.height / 2

    ctx.set_source_color( @params.legend_font_color )
    ctx.move_to( x + xtext, y + ytext )
    ctx.show_text( txt )
  end
  #
  # Render the background, then the outline of the chart.  The chart is
  # a rectangle starting at [+x+, +y+] with size +width+ and +height+.
  #
  def render_base_chart( x, y, width, height, ctx, outline_only=false )
    # The background of the chart.
    ctx.move_to( x, y )
    ctx.rectangle( x, y, width, height )
    if !outline_only
      ctx.set_source_color( @params.background_color )
      ctx.fill_preserve
    end
    # The outline of the chart.
    ctx.set_source_color( @params.outline_color )
    ctx.set_line_width( @params.outline_width )
    ctx.stroke
  end
  def render_y( x, y, width, height, ctx )
    ys = y_scale( height )
    ytype, ytypelabel = Charting.y_label_type( @graph.data.y_delta )

    for mark in 0..@graph.data.y_steps
      yval = y + height - ((mark * @graph.data.y_delta) * ys)
      ynumdelta = @graph.data.y_delta
      if @graph.data.y_delta == @graph.data.y_delta.to_i
        ynumdelta = @graph.data.y_delta.to_i 
      end

      if mark != 0 and mark != @graph.data.y_steps
        ctx.move_to( x, yval )
        ctx.line_to( x + width, yval )
        ctx.set_line_width( @params.grid_width )
        ctx.set_source_color( @params.grid_color )
        ctx.stroke
      end

      ctx.move_to( x, yval )
      ctx.line_to( x + 5, yval )
      ctx.move_to( x + width, yval )
      ctx.line_to( x + width - 5, yval )
      ctx.set_source_color( @params.outline_color )
      ctx.stroke

      ctx.select_font_face( @params.y_label_font,
                            Cairo::FONT_SLANT_NORMAL,
                            Cairo::FONT_WEIGHT_NORMAL )
      ctx.set_font_size( @params.y_label_font_size )
      txt = Charting.y_label( ytype, 
                              @graph.data.min_bound +
                                (ynumdelta * mark) ).to_s
      ext = ctx.text_extents( txt )
      return unless ext

      if @params.show_y_label_right
        ctx.move_to( x + width + 5, yval + (ext.height/2) )
        ctx.show_text( txt )
      end
      if @params.show_y_label_left
        ctx.move_to( x - 5 - ext.width, yval + (ext.height/2) )
        ctx.show_text( txt )
      end
    end
  end
  def render_x( x, y, width, height, ctx )
    xd = x_delta( width )
    @graph.data.x_dates.each do |xdate|
      mark = x + (xd * xdate["count"])
      ctx.move_to( mark, y )
      ctx.line_to( mark, y + height )
      ctx.set_line_width( @params.grid_width )
      ctx.set_source_color( @params.grid_color )
      ctx.stroke

      ctx.move_to( mark, y )
      ctx.line_to( mark, y + 5 )
      ctx.move_to( mark, y + height )
      ctx.line_to( mark, y + height - 5 )
      ctx.set_source_color( @params.outline_color )
      ctx.stroke

      ctx.select_font_face( @params.x_label_font,
                            Cairo::FONT_SLANT_NORMAL,
                            Cairo::FONT_WEIGHT_NORMAL )
      ctx.set_font_size( @params.x_label_font_size )
      txt = Charting::x_label( xdate["date"], @graph.data.x_type )
      ext = ctx.text_extents( txt )
      return unless ext

      x_text = mark - ext.width/2
      # Don't show the label if it would pass the chart's outline.
      if x_text >= x and x_text + ext.width <= x + width
        if @params.show_x_label_bottom
          ctx.move_to( x_text, y + height + 15 )
          ctx.show_text( txt )
        end
        if @params.show_x_label_top
          ctx.move_to( x_text, y - 15 )
          ctx.show_text( txt )
        end
      end
    end
  end
  def render_graphs( x, y, width, height, ctx )
#     @graphs.each do |g|
#       g["graph"].render( x, x_delta( width ), 
#                          y, @graph.data.min_bound, y_scale( height ), 
#                          height, ctx )
#     end
    @graph.render( x, x_delta( width ), 
                   y, @graph.data.min_bound, y_scale( height ), 
                   height, ctx )
  end
  def render_legend( x, y, width, height, ctx )
    ctx.select_font_face( @params.legend_font,
                          Cairo::FONT_SLANT_NORMAL,
                          Cairo::FONT_WEIGHT_NORMAL )
    ctx.set_font_size( @params.legend_font_size )
    txt = @graph.data.legend
    ext = ctx.text_extents( txt )
    return unless ext

    if @params.legend_position != ChartParams::LEGEND_NONE
      if @params.legend_position == ChartParams::LEGEND_BOTTOM
        yoff_line = height + ext.height
        yoff_text = height + ext.height + 5
      else
        yoff_line = -ext.height
        yoff_text = -(ext.height/2)
      end

      if @params.show_legend_line
        ctx.set_source_color( @graph.params.color )
        ctx.set_line_width( 2.0 )
        ctx.move_to( x, y + yoff_line )
        ctx.line_to( x + 20, y + yoff_line )
        ctx.stroke

        lineoff = 20 + 5
      else
        lineoff = 0
      end

      ctx.set_source_color( @params.legend_font_color )
      ctx.move_to( x + lineoff, y + yoff_text )
      ctx.show_text( txt )
    end

    if @params.range_legend_position != ChartParams::LEGEND_NONE
      if @params.range_legend_position == ChartParams::LEGEND_BOTTOM
        yoff_line = height + ext.height
        yoff_text = height + (ext.height/2)
      else
        yoff_line = -ext.height
        yoff_text = -(ext.height/2)
      end

      txt= @graph.data.range_legend
      ext = ctx.text_extents( txt )
      ctx.set_source_color( @params.legend_font_color )
      ctx.move_to( x + width - ext.width, y + yoff_text )
      ctx.show_text( txt )
    end
  end
end
class LinearChart < Chart
end
class LogChart < Chart
end
class VolumeChart < Chart
  def default_size
    [400, 100]
  end
  def fixed_height
    true
  end
end

if $0 == __FILE__
  require '../extern/yahoofinance'
  require './charting'
  require './chart_context'
  require './graph'
  require './graph_data'
  require '../chart_parameters'
  require 'gtk2'

  symbol = 'AOB'

  Gtk.init

  params = ChartParameters.new
  context = GtkChartContext.new( params )
  quotes = YahooFinance.get_historical_quotes_days( symbol, 50 ).reverse!
  data = PriceData.new( symbol, quotes )
  graph = LineGraph.new( data )
  chart = Chart.new
#  chart.add( graph, data )
  chart.graph = graph
  context.add( chart )

  params = ChartParams.volume_chart_params
  data = VolumeData.new( symbol, quotes )
  puts "#{data.to_s}"
  graph = VolumeGraph.new( data )
  chart = VolumeChart.new( params )
#  chart.add( graph, data )
  chart.graph = graph
  context.add( chart )

  win = Gtk::Window.new
  box = Gtk::VBox.new
#  box.pack_start( area )
  box.pack_start( context )
  win.add(box).show_all

  #win.add(canvas).show_all
  win.signal_connect( "destroy" ) { 
    Gtk.main_quit
  }

  Gtk.main
  
end
