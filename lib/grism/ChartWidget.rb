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

class ChartTimeFrames < Gtk::ListStore
  @@column_types = [ String, Integer, Integer ]
  @@column_names = %w( text tftype tfvalue )
  @@column_vals  = [
    ["1 week", Charting::DAY, 7], 
    ["2 weeks", Charting::DAY, 14], 
    ["1 month", Charting::MONTH, 1], 
    ["2 month", Charting::MONTH, 2], 
    ["3 month", Charting::MONTH, 3], 
    ["6 month", Charting::MONTH, 6], 
    ["9 month", Charting::MONTH, 9], 
    ["1 year", Charting::MONTH, 12],
    ["2 years", Charting::MONTH, 24],
    ["3 years", Charting::MONTH, 36],
    ["4 years", Charting::MONTH, 48],
    ["5 years", Charting::MONTH, 60],
    ["10 years", Charting::MONTH, 120]
  ]
  @@default_val = "1 year"

  attr_reader :default_iter

  def initialize
    super( *@@column_types )

    # Create an accessor method for each column.
    @@column_types.each_index do |index|
      instance_eval( "def #{@@column_names[index]}() return #{index} end" )
    end

    @@column_vals.each do |val|
      iter = append
      iter[text] = val[0]
      iter[tftype] = val[1]
      iter[tfvalue] = val[2]
      @default_iter = iter if val[0] == @@default_val
    end

  end

end

class ChartWidget 
# Gtk::EventBox

  def initialize( symbol, name=nil )
#    super()

    @symbol = symbol
    @sname = name
    @table = $PREFS["db"].ensure_table( @symbol )
    $PREFS["db"].ensure_table_quotes( @symbol, @table )

    # Create the chart.
    @libglade = GladeXML.new( $FPATH + GRISM::GLADE, "chart" )

#    @cparams = ChartParameters.new
    cctx = mk_chart

    @libglade["chartvbox"].pack_start( cctx )
    @model = ChartTimeFrames.new
    @libglade["chart_combo"].model = @model
    @libglade["chart_combo"].signal_connect( "changed" ) { |combo| 
      @chart["context"].invalidate if update_data( symbol )
    }
    @libglade["chart_combo"].active_iter = @model.default_iter
    @libglade["chart_label"].markup = 
      '<big><b>' + GRISM.html_escape( get_label ) + '</b></big>'
    img =  Gtk::Image.new( $FPATH + GRISM::CHARTEXPORT_ICON_16 )
    @libglade["chart_export"].remove( @libglade["chart_export"].child )
    @libglade["chart_export"].add( img )
    @libglade["chart_export"].signal_connect( "clicked" ) { |btn|
      alloc = cctx.allocation
      #d = ExportChartDialog.new
      #d.run( alloc.width, alloc.height ) do |fname, w, h|
      $PREFS["exchart"].run( alloc.width, alloc.height ) do |w, h, fname|
        #puts "Export to PNG (#{fname}, #{w}x#{h}) ..."
        c = PNGChartContext.new( fname )
        c.add( @chart["pchart"] )
        c.add( @chart["vchart"] )
        c.render( w, h )
      end
    }

    @libglade["chart"].title = "Grism: #{@symbol}"
    @libglade["chart"].show_all
  end

  def update_data( symbol )
    iter = @model.get_iter( @libglade["chart_combo"].active.to_s )
    val = @model.get_value( iter, @model.text )
    #puts "#{iter};#{val};#{val.class.name}"
    sd, ed = ago( iter[@model.tftype], iter[@model.tfvalue] )
    #puts "sd=#{sd};ed=#{ed}"

    quotes = $PREFS["db"].get_quotes( symbol, sd, ed ).reverse!
    if !quotes or quotes.length < 1
      @chart["pgraph"].data = nil
      @chart["vgraph"].data = nil
      return false 
    else
      @chart["pgraph"].data = PriceData.new( get_label, quotes )
      @chart["vgraph"].data = VolumeData.new( get_label, quotes )
      return true
    end
  end

  def mk_chart()
    #Chart.new( @cparams )
    #CairoChart.new( @cparams )

    @chart = { "context" => GtkChartContext.new,

      "pgraph" => LineGraph.new,
      "pchart" => Chart.new,

      "vgraph" => VolumeGraph.new,
      "vchart" => VolumeChart.new,
    }

    @chart["vchart"].params = ChartParams.volume_chart_params

    @chart["pchart"].graph = @chart["pgraph"]
    @chart["vchart"].graph = @chart["vgraph"]
    @chart["context"].add( @chart["pchart"] )
    @chart["context"].add( @chart["vchart"] )

#    quotes = YahooFinance.get_historical_quotes_days( symbol, 150 ).reverse!
#    data = PriceData.new( symbol, quotes )
#    data = VolumeData.new( symbol, quotes )

#    context = GtkChartContext.new( params )
#    graph = LineGraph.new( data )
#    chart = Chart.new
#    chart.set_graph( graph )
#    context.add_chart( chart )


#    params = ChartParams.volume_chart_params
#    graph = VolumeGraph.new( data )
#    chart = VolumeChart.new( params )
#    chart.set_graph( graph )
#    context.add_chart( chart )

    @chart["context"]
  end

  def ago( tftype, tfvalue )
    today = Date.today

    #puts "ago( #{tftype}, #{tfvalue} )"
    case tftype
    when Charting::DAY
      return [today - tfvalue, today]
    when Charting::MONTH
      return [today - (tfvalue*Charting::DIM), today]
    end
    return [today - (12*Charting::DIM), today]
  end

  def get_label
    "#{@symbol}" + (@sname != nil ? " - #{@sname}" : "")
  end
end

if $0 == __FILE__

  $LOAD_PATH.unshift ".."
  $FPATH = ".."

  require './grism_prefs'
  require './grism_ui_helpers'

  $PREFS = GRISM.init_prefs
  GRISM.init_config_dir
  GRISM.init_db

  Gtk.init

  c = ChartWidget.new( "WMT" )

  Gtk.main

end
