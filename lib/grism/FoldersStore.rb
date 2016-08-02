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

# Originally folders.rb (Folders)

class FoldersStore < Gtk::TreeStore

  include GenericStore
  include GrismSignal

  FOLDER_PARENT = 0
  FOLDER_WATCHLIST = 1
  FOLDER_PORTFOLIO = 2

  @@columns = [
    [Integer, "ftype"],
    [String, "name"],
    [Float, "today"],
    [Float, "overall"],
    [TrueClass, "wltree"],
    [TrueClass, "pftree"],
    [Object, "folder"]
  ]

  attr_reader :wl_parent, :pf_parent

  def initialize()
    super( *get_column_types( @@columns) )
    init_column_accessors( @@columns )

    # Initialize the signals exported by this object.
    init_signals( ["add", "remove"] )

    @wl_parent = append( nil )
    @wl_parent[ftype] = FOLDER_PARENT
    @wl_parent[name] = "WatchLists"
    @wl_parent[wltree] = true
    @wl_parent[pftree] = false
    @wl_parent[folder] = GRISM.new_wp_widget( 'wl_parent', FOLDER_PARENT )
    @wl_parent[folder].connect_button( "wl_parent_new" ) { 
      GRISM.new_watchlist_folder()
    }

    @pf_parent = append( nil )
    @pf_parent[ftype] = FOLDER_PARENT
    @pf_parent[name] = "Portfolios"
    @pf_parent[wltree] = false
    @pf_parent[pftree] = true
    @pf_parent[folder] = GRISM.new_wp_widget( 'pf_parent', FOLDER_PARENT )
    @pf_parent[folder].connect_button( "pf_parent_new" ) { 
      GRISM.new_portfolio_folder()
    }
  end

  def add( type, widget )
    case type
    when FOLDER_WATCHLIST
      listiter = append( @wl_parent )
      listiter[wltree] = true
      listiter[pftree] = false
    when FOLDER_PORTFOLIO
      listiter = append( @pf_parent )
      listiter[wltree] = false
      listiter[pftree] = true
    end

    listiter[ftype] = type
    listiter[name] = widget.store.list_name
    listiter[today] = widget.store.today_total
    listiter[overall] = widget.store.overall_total
    listiter[folder] = widget

    widget.store.signal_connect( "today" ) { |store| 
      listiter[today] = store.today_total
    }
    widget.store.signal_connect( "overall" ) { |store| 
      listiter[overall] = store.overall_total
    }
    widget.store.signal_connect( "name" ) { |store| 
      listiter[name] = store.list_name
    }

    call_signal( "add", type, widget, listiter.path )
    return listiter.path
  end

  def delete( iter )
    t = iter[ftype]
    w = iter[folder]
    remove( iter )
    call_signal( "remove", t, w )
  end

  def find_folder( fldr )
    each do |model, path, iter|
      return iter if iter[folder] == fldr
    end
    nil
  end

  def each_iter
    each do |model, path, iter|
      yield iter
    end
  end

end
