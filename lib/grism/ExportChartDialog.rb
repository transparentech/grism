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

class ExportChartSizes < Gtk::ListStore
  @@column_types = [ String, Integer, Integer ]
  @@column_names = %w( text width height )
  @@column_vals = [
    ["400 x 300", 400, 300 ],
    ["600 x 450", 600, 450 ],
    ["800 x 600", 800, 600 ],
    ["1024 x 768", 1024, 768 ],
    ["1600 x 1200", 1600, 1200 ]
  ]
  @@default_val = "400 x 300"

  attr_reader :default_iter

  def initialize()
    super( *@@column_types )

    # Create an accessor method for each column.
    @@column_types.each_index do |index|
      instance_eval( "def #{@@column_names[index]}() return #{index} end" )
    end

    @@column_vals.each do |val|
      iter = append
      iter[text] = val[0]
      iter[width] = val[1]
      iter[height] = val[2]
      @default_iter = iter if val[0] == @@default_val
    end

  end

end

class ExportChartDialog < GenericDialog

  def initialize( libglade=nil )
    super( "chartexportdialog", libglade )

    @model = ExportChartSizes.new
    @libglade["exchart_fixedcombo"].model = @model
    @libglade["exchart_fixedcombo"].active_iter = @model.default_iter
    @libglade["exchart_fixedcombo"].sensitive = false

    @libglade["exchart_defsize"].signal_connect( "toggled" ) do |widget|
      if @libglade["exchart_fixedsize"].active?
        @libglade["exchart_fixedcombo"].sensitive = true
      else
        @libglade["exchart_fixedcombo"].sensitive = false
      end
    end

    @libglade["exchart_file"].do_overwrite_confirmation = true
    @libglade["exchart_file"].current_folder = $PREFS["configchartsdir"]
    filter = Gtk::FileFilter.new
    filter.name = "PNG images (*.png)"
    filter.add_mime_type( "image/png" )
    filter.add_pattern( "*.png" )
    @libglade["exchart_file"].add_filter( filter )
    filter = Gtk::FileFilter.new
    filter.name = "All Files"
    filter.add_pattern( "*" )
    @libglade["exchart_file"].add_filter( filter )
  end

  protected

  def response_ok( args )
    ret = []

    if @libglade["exchart_fixedsize"].active?
      iter = @model.get_iter( @libglade["exchart_fixedcombo"].active.to_s )
      ret << @model.get_value( iter, @model.width )
      ret << @model.get_value( iter, @model.height )
    else
      ret << args[0]
      ret << args[1]
    end

    name = @libglade["exchart_file"].filename
    if !name or name.length < 1
      self.close = false
    elsif name !~ /\.png/
      name += ".png"
      self.close = true
    else
      self.close = true
    end
    ret << name

    ret
  end

  def response_canceled( args )
    self.close = true
    nil
  end

  def setup( args )
    defwidth = args[0]
    defheight = args[1]

    @libglade["exchart_winsize"].markup = "<b>#{defwidth} x #{defheight}</b>"
    @libglade["exchart_file"].unselect_all
    @libglade["exchart_file"].current_name = ""
  end

end
