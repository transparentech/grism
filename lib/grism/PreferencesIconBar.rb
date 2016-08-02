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

class PreferencesIconBar < Gtk::ListStore

  @@column_types = [ String, Gdk::Pixbuf, Integer ]
  @@column_names = %w( text pixbuf pos )

  def initialize( libglade )
    super( @@column_types[0], @@column_types[1], @@column_types[2] )

    # Create an accessor method for each column.
    @@column_types.each_index do |index|
      instance_eval( "def #{@@column_names[index]}() return #{index} end" )
    end

    iter = append()
    iter[text] = "<b>General</b>"
    iter[pixbuf] = Gdk::Pixbuf.new( $FPATH + GRISM::PREFS_GENERAL_ICON_32 )
    iter[pos] = 0
    iter = append()
    iter[text] = "<b>Quotes</b>"
    iter[pixbuf] = Gdk::Pixbuf.new( $FPATH + GRISM::PREFS_QUOTES_ICON_32 )
    iter[pos] = 1
    iter = append()
    iter[text] = "<b>Internet</b>"
    iter[pixbuf] = Gdk::Pixbuf.new( $FPATH + GRISM::PREFS_INTERNET_ICON_32 )
    iter[pos] = 2

    connect_to_libglade( libglade )

  end

  protected 

  def connect_to_libglade( libglade )
    #iconbar = PreferencesIconBar.new()
    iview = libglade["pref_iconview"]
    iview.model = self
    iview.markup_column = self.text
    iview.pixbuf_column = self.pixbuf
    iview.item_width = 68
    #iview.row_spacing = 15
    iview.margin = 10
    iview.signal_connect( "selection_changed" ) do |iv|
      iv.selected_each do |iv, path|
        iter = self.get_iter( path )
        libglade["pref_notebook"].page = iter[self.pos]
      end
    end
    # nb_wl_img = libglade["nb_watchlist_img"]
    # nb_wl_img.pixbuf = Gdk::Pixbuf.new( "eye-icon-trans-16.gif" )
  end

end

