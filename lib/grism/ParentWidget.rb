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

class ParentWidget < GrismFolderTypeWidget

  def initialize( widget_name )
    super()

    # Create the list widget.
    @libglade = GladeXML.new( $FPATH + GRISM::GLADE, widget_name )
    add( @libglade[ widget_name ] )

    # This is a bit of a hack to get the icon next to the name, but it
    # looks nice so whatever.
    if widget_name[0,1] == 'w'
      img = Gtk::Image.new( $FPATH + GRISM::WATCHLIST_ICON_24 )
    else
      img = Gtk::Image.new( $FPATH + GRISM::PORTFOLIO_ICON_24 )
    end
    img.xpad = 5
    img.show
    @libglade[widget_name + '_hbox'].pack_start( img, true, false )
    show_all
  end

  def connect_button( btn_name )
    @libglade[btn_name].signal_connect( "clicked" ) { 
      yield
    }
  end

end
