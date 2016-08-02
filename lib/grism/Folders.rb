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
# Class that manages the left-hand side menu of watchlists and portfolios.
#
# *************************************************************************
class Folders

  include GrismTreeViews
  include GrismSignal

  attr_reader :view, :store

  def initialize( view, model )
    @view = view
    @store = model
    @view.model = @store

    # Initialize the signals exported by this object.
    init_signals( ["switch_to", "watchlists_expanded", "watchlists_collapsed",
                    "portfolios_expanded", "portfolios_collapsed"] )

    addStringCol( @view, "Folder", @store.name ) do 
      |col, renderer, model, iter|
      if iter[@store.ftype] == FoldersStore::FOLDER_PARENT
        renderer.weight = 700
      else
        renderer.weight = 400
      end
    end
    addNumericCol( @view, "Today", @store.today, "%.2f%%" ) do 
      |col, renderer, model, iter|
      if iter[@store.ftype] == FoldersStore::FOLDER_PARENT
        renderer.text = ""
      else
        movementColor( iter, renderer, @store.today, false )
      end
    end
    addNumericCol( @view, "Overall", @store.overall, "%.2f%%" ) do 
      |col, renderer, model, iter|
      if iter[@store.ftype] == FoldersStore::FOLDER_PARENT
        renderer.text = ""
      else
        movementColor( iter, renderer, @store.overall, false )
      end
    end

    @view.selection.signal_connect( "changed" ) do |selection|
      iter = selection.selected
      if !iter
        # If the selection is removed, just reselect the same row.
        # This way there should never be a time when there is no
        # row/folder selected.  This makes managing the sensitivity of
        # the menu easier. :-)
        selection.select_path( Gtk::TreePath.
                               new( $PREFS['folderslist.selected'] ) )
      elsif iter[@store.folder]
        GRISM.switch_notebook_to_folder( iter[@store.folder] )
        call_signal( "switch_to", iter[@store.ftype], 
                     iter[@store.folder], iter.path )
      end
    end
    @view.signal_connect( "row-expanded" ) do |tview,iter,path|
      if path.to_s == @store.wl_parent.path.to_s
        call_signal( "watchlists_expanded" )
      elsif path.to_s == @store.pf_parent.path.to_s
        call_signal( "portfolios_expanded" )
      end
    end
    @view.signal_connect( "row-collapsed" ) do |tview,iter,path|
      # If the row being collapsed is the parent of the currently
      # selected row, then we want to select the row being collapsed
      # so that there is still a selection in the list.  At this stage
      # there actually is no selection so we must use the value cached
      # in $PREFS to decide.
      if path.ancestor?( Gtk::TreePath.new( $PREFS['folderslist.selected'] ) )
        select_path( path.to_s )
      end
      if path.to_s == @store.wl_parent.path.to_s
        call_signal( "watchlists_collapsed" )
      elsif path.to_s == @store.pf_parent.path.to_s
        call_signal( "portfolios_collapsed" )
      end
    end
    @view.signal_connect( "row-activated" ) do |view, path, column|
      if iter = view.model.get_iter( path )
        iter[@store.folder].show_properties
      end
    end

  end

  def selected_iter
    iter = @view.selection.selected
    return nil if !iter
    iter
  end

  def selected_folder
    iter = @view.selection.selected
    return nil if !iter
    iter[@store.folder]
  end

  def selected_type
    iter = @view.selection.selected
    return nil if !iter
    iter[@store.ftype]
  end

  def get_iter( path_str )
    @view.model.get_iter( Gtk::TreePath.new( path_str ) )
  end

  def select_path( path_str )
    @view.selection.select_path( Gtk::TreePath.new( path_str ) )
  end
  def select_iter( iter )
    @view.selection.select_iter( iter )
  end
  def select_folder( fldr )
    @view.selection.select_iter( @store.find_folder( fldr ) )
  end

  def expand_watchlists
    @view.expand_row( @store.wl_parent.path, true )
  end
  def watchlists_expanded?
    @view.row_expanded( @store.wl_parent.path )
  end
  def expand_portfolios
    @view.expand_row( @store.pf_parent.path, true )
  end
  def portfolios_expanded?
    @view.row_expanded( @store.pf_parent.path )
  end

  def init_dnd
    # Drag-and-drop features.

    # This didn't work out. It's too complicated to make it work
    # exactly like I imagine it.  I'm putting it aside for the moment.
    # Maybe I'll give it another try when I have more
    # time/patience/brains.

#     @view.enable_model_drag_dest( [["watchlist", 
#                                       Gtk::Drag::TARGET_SAME_APP, 
#                                       12345]],
#                                   Gdk::DragContext::ACTION_COPY |
#                                     Gdk::DragContext::ACTION_MOVE )
#     @view.signal_connect("drag-data-received") do 
#       |w, dc, x, y, selectiondata, info, time|
#       # w == @view
#       mx,my = w.tree_to_widget_coords( x, y )
#       puts "FL:#{x},#{y};#{mx},#{my}"
#       path,pos = w.get_dest_row( x, y )
#       iter = w.model.get_iter( path )
#       pathstr,data = selectiondata.data.split(/~/,2)
#       src_iter = get_iter( pathstr )
#       puts "FL:ddr:#{w.to_s};#{info};#{path.to_s};#{iter[0]};#{iter[1]}"
#       puts "FL - From: #{src_iter[name]}"
#       puts "FL - Data: #{data}"
#       puts "FL - To:   #{iter[name]}"
#       if src_iter[name] == iter[name]
#         Gtk::Drag.finish( dc, false, false, time )
#       else
#         Gtk::Drag.finish( dc, true, false, time )
#       end
#     end
#     @view.signal_connect("drag-drop") do |w, dc, x, y, time|
#       puts "FL:dd:#{w.to_s};#{dc.targets[0].name}"
#     end
#     @view.signal_connect( "drag-motion") do |w, dc, x, y, time|
#       puts "FL:dm:#{x},#{y}"
#     end
  end
end
