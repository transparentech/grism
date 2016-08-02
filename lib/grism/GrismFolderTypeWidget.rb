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

# *************************************************************************
#
# Base class for all widgets that are connected to an entry in the
# FoldersWidget Gtk::TreeStore (tree on the left side of the interface
# that acts as a menu of available watchlists and portfolios).  This
# includes (leaf nodes in hierarchy) WatchListWidget, PortfolioWidget
# and ParentWidget.
#
# *************************************************************************
class GrismFolderTypeWidget < Gtk::EventBox

  include GrismSignal

  def initialize()
    super()

    # Initialize the signals exported by this object.
    init_signals( ["has_selected"] )
  end

  def post_notebook_append()
  end

  def folder_type
    "None"
  end

  def icon_name
    GRISM::GRISMFOLDERTYPE_ICON_32
  end

  # 
  # Abstract "Folder" menu methods.
  #

  def refresh_noinfobar
  end
  def refresh(errblk=nil)
  end
  def save
  end
  def delete
  end
  def show_properties
  end

  #
  # Abstract "Stock" menu methods.
  #

  def add_element
  end
  def details( iter )
  end
  def chart( iter )
  end
  def remove_element( iter )
  end
  def moveto( iter )
  end
  def copyto( iter )
  end
  def split( iter )
  end
  def rename( iter )
  end

  # 
  # Misc methods
  #

  def has_selected?
    false
  end

  def selected
    nil
  end

  def switch_to_me()
    GRISM.menu_stock_sensitivity_opts( GRISM::MENU_STOCK_OFF_OPTS )
  end

  def context_menu_popup( iter )
  end

end
