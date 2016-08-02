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

class MoveCopyDialog < GenericDialog

  @@column_names = %w( name )
  
  include GrismTreeViews

  def initialize( model, libglade=nil )
    super( "mvcpdialog", libglade )

    @view = @libglade["mvcpdialog_view"]
    @model = model
    @filtercol = @model.wltree

    @view.model = Gtk::TreeModelFilter.new( @model )
    @view.model.set_visible_func() { |model, iter|
      iter[@filtercol]
    }

    # Connect to the "New" button.
    @libglade["mvcpdialog_new"].signal_connect( "clicked" ) { |widget|
      path = nil
      if @filtercol == @model.wltree
        path = GRISM.new_watchlist_folder()
      else
        path = GRISM.new_portfolio_folder()
      end
      if path
        #puts "added at: #{path}"
        @view.scroll_to_cell( path, nil, false, 0.0, 0.0 ) if path
        @view.selection.select_path( path ) if path
        @view.model.refilter
      end
    }
    # Prevent selection of the Parent folders.
    @view.selection.set_select_function() { |selection, model, path, curpath|
      iter = model.get_iter( path )
      if iter[@model.ftype] == FoldersStore::FOLDER_PARENT
        false
      else
        true
      end
    }

    addStringCol( @view, "Folder", @model.name ) do
      |col, renderer, model, iter|
      if iter[@model.ftype] == FoldersStore::FOLDER_PARENT
        renderer.weight = 700
      else
        renderer.weight = 400
      end
    end
  end

  protected

  def response_ok( args )
    ret = []

    iter = @view.selection.selected
    # Don't close if nothing was selected.
    if !iter
      self.close = false
    else
      self.close = true
    end

    ret << iter[@model.name]
    ret << iter[@model.folder]
    ret
  end

  def response_canceled( args )
    # Always close on cancel.
    self.close = true
    nil
  end

  def response_other( response, args )
    # Never close on other (in this case, "New").
    self.close = false
    nil
  end

  def setup( args )
    ftype = args[0]
    case ftype
    when FoldersStore::FOLDER_WATCHLIST
      @dialog.title = "Select Watchlist"
      @filtercol = @model.wltree
      @view.model.refilter
    when FoldersStore::FOLDER_PORTFOLIO
      @dialog.title = "Select Portfolio"
      @filtercol = @model.pftree
      @view.model.refilter
    end
    @view.expand_all

    #puts "setup( #{args[0]} ) : #{@filtercol}"
  end

end
