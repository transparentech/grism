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

class WatchListWidget < WPListWidget

  def initialize( wplist_row )
    super()

    set_store( WatchListStore.new( wplist_row ) )
    @fview_ext.model = @store.liststore

    @libglade['folder_std_view'].icon_widget =
      Gtk::Image.new( $FPATH + GRISM::WATCHLIST_ICON_24 )
    @libglade['folder_std_view'].show_all
    @libglade['folder_ext_view'].icon_widget =
      Gtk::Image.new( $FPATH + GRISM::EXTENDEDVIEW_ICON_24 )
    @libglade['folder_ext_view'].show_all

    # Hide the portfolio specific buttons.
    @libglade['folder_cash_btn'].hide
    @libglade['folder_other_sep'].hide
    @libglade['folder_hist_view'].hide
    @libglade['folder_pf_view'].hide
    @libglade['folder_view_pf_sep'].hide

    #
    # Set-up the watchlist columns.
    #

    addPixbufCol( @fview, 'Important', @store.importantPix, 
                  GRISM::IMPORTANT_FALSE_ICON_9 ) do |iter|
      @store.toggle_important( iter )
    end
    addStringCol( @fview, 'Symbol', @store.symbol, "%s", nil, true )
    addStringCol( @fview, 'Name', @store.name )
    renderer = addNumericCol( @fview, 'Last', @store.lastTrade )
    renderer.editable = true
    renderer.signal_connect( 'edited' ) do |rend, path, text|
      editWatchlistColumn( @store.lastTrade, path, text.to_f )
    end
    addNumericCol( @fview, 'Change', @store.change ) do 
      |col, renderer, model, iter|
      lastTradeColor( iter, renderer )
    end
    addNumericCol( @fview, 'Percent', @store.percent, "%.2f%%" ) do 
      |col, renderer, model, iter|
      lastTradeColor( iter, renderer )
    end
    addNumericCol( @fview, 'Previous Close', @store.previousClose )
    addNumericCol( @fview, 'Open', @store.open )
    renderer = addNumericCol( @fview, 'Watch Start', @store.watchStart )
    renderer.editable = true
    renderer.signal_connect( 'edited' ) do |rend, path, text|
      editWatchlistColumn( @store.watchStart, path, text.to_f )
    end
    addNumericCol( @fview, 'Change', @store.watchChange ) do 
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.watchChange )
    end
    addNumericCol( @fview, 'Percent', @store.watchPercent, 
                   "%.2f%%" ) do 
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.watchPercent )
    end

    #
    # Setup the ratio (fundamentals) list.
    #

    addPixbufCol( @fview_ext, 'Important', @store.importantPix, 
                  GRISM::IMPORTANT_FALSE_ICON_9 ) do |iter|
      @store.toggle_important( iter )
    end
    addStringCol( @fview_ext, 'Symbol', @store.symbol, "%s", nil, true )
    addStringCol( @fview_ext, 'Name', @store.name )
    addNumericCol( @fview_ext, 'Last', @store.lastTrade )
    addNumericCol( @fview_ext, 'MarketCap', @store.marketCap, "%s" )
    addNumericCol( @fview_ext, 'EPS', @store.eps )
    addNumericCol( @fview_ext, 'P/E', @store.peRatio )
    addNumericCol( @fview_ext, 'PEG', @store.pegRatio )
    addNumericCol( @fview_ext, 'Dividend', @store.dividend, "%s" )
    addNumericCol( @fview_ext, 'Yield', @store.dividendYield, "%s" )
    addNumericCol( @fview_ext, 'Book Value', @store.bookValue )
    addNumericCol( @fview_ext, 'Price/Sales', @store.pricePerSales )
    addNumericCol( @fview_ext, 'Price/Book', @store.pricePerBook )
    addStringCol( @fview_ext, 'Exchange', @store.stockExchange )

    # Searching
#    @fview.search_column = srch_col

    # Make sure the selection changes are shown in both lists.
#     @fview.selection.signal_connect( 'changed' ) do |selection|
#       selectionChange( selection.selected, @fview_ext )
#     end
#     @fview_ext.selection.signal_connect( 'changed' ) do |selection|
#       selectionChange( selection.selected, @fview )
#     end

    #
    # Make the price and ratio lists scroll together (i.e. you
    # scroll in one and the other scrolls behind the sceens so that
    # when you view the other one the same rows are showing.
    #
    hadj = @libglade['scroll_folderlist'].vadjustment
    hextadj = @libglade['scroll_folderlist_ext'].vadjustment
    hadj.signal_connect( 'value-changed' ) do |hadj|
      hextadj.value = hadj.value if hadj.value != hextadj.value
    end
    hextadj.signal_connect( 'value-changed' ) do |hextadj|
      hadj.value = hextadj.value if hextadj.value != hadj.value
    end
  end

  # This is a bit of a hack.  The first time the second page is
  # visible, the scroll position is set to 0 (value=0, by who? i
  # duno).  This ensures that it has been made visible so that the
  # scrolling is connected from the start.  It also ensures that the
  # columns are resized appropriately if the list is not visible.
  #
  # And this method must be called after the widget has been added to
  # the notebook, otherwise the same problems occure. Must be
  # something in the notebook#append_page method that resets stuff.
  # idono.
  #
  # See GRISM.new_wp_widget for calling order.
  def post_notebook_append()
    @libglade['folder_views'].page = 1
    @libglade['folder_views'].page = 0
  end

  def folder_type
    'WatchList'
  end

  def icon_name
    GRISM::WATCHLIST_ICON_16
  end

  def refresh_noinfobar
    @store.refresh
  end
  def refresh(errblk = lambda { |e|
                Gtk.idle_add() { 
                  GRISM.yahoo_problem_dlg( e, @store.list_name )
                  false
                }
              })
    $PREFS['infobar'].run( "Updating watch list ...", errblk ) do |ib|
        @store.refresh
    end
  end
  def add_element
    GRISM.yahoo_dialog_rescue( $PREFS['wldialog'] ) { 
      $PREFS['wldialog'].run( :iter => nil, 
                              :store => @store,
                              :wtype => 'add' ) do |ret|
        #      |sym, dt, ws, cm, imp|
        @store.add_row( ret[:symbol], ret[:date], ret[:price], 
                        ret[:comment], ret[:important] )
      end
    }
  end
  def details( iter )
    GRISM.yahoo_dialog_rescue( $PREFS['wldialog'] ) { 
      $PREFS['wldialog'].run( :iter => iter, 
                              :store => @store,
                              :wtype => 'details' ) do |ret|
        #      |sym, dt, ws, cm, imp|
        @store.modify_row( iter, ret[:date], ret[:price], 
                           ret[:comment], ret[:important] )
      end
    }
  end
  def remove_element( iter )
    @store.remove_row( iter )
  end

  def moveto( iter )
    $PREFS['mvcpdialog'].run( FoldersStore::FOLDER_WATCHLIST ) do |ret|
      ret[1].store.add_row_from_iter( iter )
      @store.remove_row( iter )
      #puts "ok: move to->#{ret[0]} : #{@store.iter_to_csv( iter )}"
    end
  end

  def copyto( iter )
    $PREFS['mvcpdialog'].run( FoldersStore::FOLDER_WATCHLIST ) do |ret|
      ret[1].store.add_row_from_iter( iter )
      #puts "ok: copy to->#{ret[0]} : #{@store.iter_to_csv( iter )}"
    end
  end

  def split( iter )
    $PREFS['splitdialog'].run do |x, y, log|
      @store.split( iter, x, y, log )
    end
  end
  def rename( iter )
    $PREFS['renamedialog'].run( :iter => iter,
                                :store => @store ) do |newname, log|
      @store.rename( iter, newname, log )
    end
  end

  def context_menu_popup( iter )
    puts "WLW: ctx menu for - #{iter[@store.symbol]}"
  end

#   def switch_to_me()
#     selectionChange( selected() ) { |sel, iter|
#       if sel == :off
#         @fview.selection.unselect_all
#         @fview_ext.selection.unselect_all
#       else
#         @fview.selection.select_iter( iter )
#         @fview_ext.selection.select_iter( iter )
#       end
#     }
#   end

  protected 

  def selection_changed_in_fview( iter )
    super( iter )
    sync_view_selection( iter, @fview_ext )
  end
  def selection_changed_in_fview_ext( iter )
    super( iter )
    sync_view_selection( iter, @fview )
  end

  def lastTradeColor( iter, renderer )
    if iter[ @store.lastTrade ] == 0
      renderer.foreground = 'black'
    elsif iter[ @store.lastTrade ] >= iter[ @store.previousClose ]
      renderer.foreground = 'darkgreen'
    else
      renderer.foreground = 'red'
    end
  end

  def editWatchlistColumn( column, path, val )
    @store.set_row_column( path, column, val )
  end

  private

  def sync_view_selection( selected_iter, view )
    if !selected_iter
      view.selection.unselect_all
    else
      view.selection.select_iter( selected_iter )
    end
  end

  def init_dnd
    # Drag-and-Drop

    # This didn't work out. It's too complicated to make it work
    # exactly like I imagine it.  I'm putting it aside for the moment.
    # Maybe I'll give it another try when I have more
    # time/patience/brains.

#     @fview.enable_model_drag_source( Gdk::Window::BUTTON1_MASK,
#                                      [["watchlist", 
#                                          Gtk::Drag::TARGET_SAME_APP, 
#                                          12345],
#                                        ["watchlist2", 
#                                          Gtk::Drag::TARGET_SAME_WIDGET, 
#                                          123456]], 
#                                      Gdk::DragContext::ACTION_COPY |
#                                        Gdk::DragContext::ACTION_MOVE )
#     @fview.enable_model_drag_dest( [["watchlist2", 
#                                     Gtk::Drag::TARGET_SAME_WIDGET, 
#                                     123456]],
#                                   Gdk::DragContext::ACTION_COPY |
#                                     Gdk::DragContext::ACTION_MOVE )
#     @fview.signal_connect( "drag-data-get" ) do 
#       |widget, context, selectiondata, info, time|
#       # widget == @fview
#       iter = widget.selection.selected
#       puts "WLW:ddg:#{widget.to_s};#{info};#{iter[2]};#{iter[3]}"
#       selectiondata.set( Gdk::Selection::TYPE_STRING, 
#                          "#{@storeiter.path.to_s}~#{@store.iter_to_csv(iter)}" )
#     end
#     @fview.signal_connect("drag-data-received") do 
#       |w, dc, x, y, selectiondata, info, time|
#       path,pos = w.get_dest_row( x, y )
#       iter = w.model.get_iter( path )
#       puts "WLW:ddr:#{w.to_s};#{info}"
#       puts "WLW:#{selectiondata.data};#{info};#{iter[2]};#{pos.to_s}"
#     end
#     @fview.signal_connect( "drag-end" ) do |w,dc|
#       puts "WLW:de:#{w.to_s};#{dc.drag_drop_succeeded?}"
#     end
#     @fview.signal_connect( "drag-drop" ) do |w,dc,x,y,time|
#       puts "WLW:dd:#{w.to_s};#{x},#{y}"
#     end
  end
end
