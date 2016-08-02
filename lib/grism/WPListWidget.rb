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

class WPListWidget < GrismFolderTypeWidget

  include GrismTreeViews

  @@glade_widget_name = "folder"

  attr_reader :libglade, :store

  def initialize()
    super()
    @store = nil

    # Create the treeview widget.
    @libglade = GladeXML.new( $FPATH + GRISM::GLADE, @@glade_widget_name )
    add( @libglade[ @@glade_widget_name ] )
    show_all

    @fview = @libglade["folderview"]
    @fview_ext = @libglade["folderview_ext"]
    @title_lbl = @libglade["folder_title"]
    @selected_fview = @fview

    # Initialize the signals for this widget.
    init_signals( [ 'std_view_shown', 'ext_view_shown',
                    'pf_view_shown', 'hist_view_shown',
                    'selection_changed'] )

    # Clicking on the refresh button in the toolbar.
    @libglade["folder_refresh_btn"].signal_connect( "clicked" ) { 
      refresh
    }
    # Clicking on the add button in the toolbar.
    @libglade["folder_add_btn"].signal_connect( "clicked" ) { 
      add_element
    }
    # Clicking on the details button in the toolbar.
    @libglade["folder_details_btn"].signal_connect( "clicked" ) { 
#      iter = @fview.selection.selected
      iter = @selected_fview.selection.selected
      return if !iter
      details( iter )
    }
    # Clicking on the chart button in the toolbar.
    @libglade["folder_chart_btn"].signal_connect( "clicked" ) { 
      iter = @selected_fview.selection.selected
      return if !iter
      chart( iter )
    }
    @libglade["folder_chart_btn"].icon_widget = 
      Gtk::Image.new( $FPATH + GRISM::CHARTING_ICON_24 )
    @libglade["folder_chart_btn"].show_all
    # Clicking on the remove button in the toolbar.
    @libglade["folder_remove_btn"].signal_connect( "clicked" ) { 
#      iter = @fview.selection.selected
      iter = @selected_fview.selection.selected
      return if !iter
      remove_element( iter )
    }

    # Clicking on the "standard"/watchlist radio-button in the toolbar.
    @libglade["folder_std_view"].signal_connect( "toggled" ) do |radio|
      @libglade["folder_views"].page = 0
      @selected_fview = @fview
      call_signal( 'std_view_shown' ) if ( radio.active? )
    end
    # Clicking on the "extended" radio-button in the toolbar.
    @libglade["folder_ext_view"].signal_connect( "toggled" ) do |radio|
      @libglade["folder_views"].page = 1
      @selected_fview = @fview_ext
      call_signal( 'ext_view_shown' ) if ( radio.active? )
    end
    # Clicking on the "portfolio" radio-button in the toolbar.
    @libglade["folder_pf_view"].signal_connect( "toggled" ) do |radio|
      #puts "toggled - pf_view"
      @libglade["folder_views"].page = 0
      @selected_fview = @fview
      call_signal( 'pf_view_shown' ) if ( radio.active? )
    end
    # Clicking on the "history" radio-button in the toolbar.
    @libglade["folder_hist_view"].signal_connect( "toggled" ) do |radio|
      #puts "toggled - hist_view"
      @libglade["folder_views"].page = 1
      @selected_fview = @fview_ext
      call_signal( 'hist_view_shown' ) if ( radio.active? )
    end

    # Set the icon for this type of folder.
    img = Gtk::Image.new( $FPATH + icon_name() )
    img.xpad = 5
    img.show
    @libglade["folder_img_hbox"].pack_start( img )

    # Initial sensitivity is what is set by default in glade.

    # Show the details dialog when an entry is doubled-clicked.
    @fview.signal_connect( "row-activated" ) do |view, path, column|
      if iter = view.model.get_iter( path )
        details( iter )
      end
    end
    @fview_ext.signal_connect( "row-activated" ) do |view, path, column|
      if iter = view.model.get_iter( path )
        details( iter )
      end
    end

    # Make sure the selection changes are propogated.
    @fview.selection.signal_connect( 'changed' ) do |selection|
#      call_signal( 'selection_changed', selection.selected, :fview )
#      selection_changed( selection.selected, :fview )#, @fview_ext )
      #puts "fview.selection.signal_connect"
      selection_changed_in_fview( selection.selected )
    end
    @fview_ext.selection.signal_connect( 'changed' ) do |selection|
#      call_signal( 'selection_changed', selection.selected, :fview_ext )
#      selection_changed( selection.selected, :fview_ext )#, @fview )
      #puts "fview_ext.selection.signal_connect"
      selection_changed_in_fview_ext( selection.selected )
    end

    # Want to save if the rows are reordered (DnD), but this doesn't
    # seem to work.
    #
    # @store.signal_connect( "rows-reordered" ) do |model,path,iter,new_order|
     # puts "rows-reordered"
    #end

    # We will need something like this when we have context menus 
    # (i.e. popups).
    #
    # @fview.signal_connect( "button_press_event") do |widget, event|
    #  do_context_menu( @fview, event )
    #end
    # @fview_ext.signal_connect( "button_press_event") do |widget, event|
    #  do_context_menu( @fview_ext, event )
    #end

  end

  def save
    @store.save if @store
  end

  def folder_type
    "None"
  end

  def show_properties
    $PREFS["folderdialog"].run( :name => @store.list_name, 
                                :desc => @store.list_desc, 
                                :type => folder_type,
                                :prefs => @store.get_preferences() ) do |ret|
      @store.list_name = ret[:name]
      @store.list_desc = ret[:desc]
      @store.set_preferences( ret[:prefs] )
    end
  end

  def chart( iter )
    #puts "Show the chart! - #{iter[@store.symbol]}; #{iter[@store.name]}"
    errblk = lambda { |e|
      Gtk.idle_add() { 
        GRISM.yahoo_problem_dlg( e, iter[@store.symbol] )
        false
      }
    }
    $PREFS["infobar"].run( "Loading chart ...", errblk ) do |ib|
      ChartWidget.new( iter[@store.symbol], iter[@store.name] )
    end
  end

  def has_selected?
#    @libglade["folder_details_btn"].sensitive?
    return ( @selected_fview.selection.selected != nil )
  end

  def selected
#    @fview.selection.selected    
    @selected_fview.selection.selected    
  end

  def set_preferences( prefs )
    @store.set_preferences( prefs )
  end

  def switch_to_me()
    set_actions_sensitivity( get_action_opts_for_iter( selected() ) )
  end

  protected

  def selection_changed_in_fview( iter )
    #puts "in_fview - #{iter[0]}"
    set_actions_sensitivity( get_action_opts_for_iter( iter ) )
  end
  def selection_changed_in_fview_ext( iter )
    #puts "in_fview_ext - #{iter[1]}"
    set_actions_sensitivity( get_action_opts_for_iter( iter ) )
  end
#   def selection_changed_fview_hist( iter )
#   end

#   def actionSensitivity( val )
#     @libglade["folder_details_btn"].sensitive = val
#     @libglade["folder_chart_btn"].sensitive = val
#     @libglade["folder_remove_btn"].sensitive = val
#     call_signal( "has_selected", val )
#   end

  def set_actions_sensitivity( opts )
    set_action_bar_sensitivity( opts )
    GRISM.menu_stock_sensitivity_opts( opts )
  end

  def get_action_opts_for_iter( iter )
    @store.get_action_opts_for_iter( iter )
  end

#   def set_actions_sensitivity( iter, opts )
#     if !iter or @store.static_row?( iter )
#       puts "selectionChange off"
# #      tview.selection.unselect_all
#       set_action_bar_sensitivity( GRISM::MENU_STOCK_NO_SELECT_OPTS )
#       GRISM.menu_stock_sensitivity_opts( GRISM::MENU_STOCK_NO_SELECT_OPTS )
#       yield :off, nil  if block_given?
#     else
#       puts "selectionChange on"
# #      tview.selection.select_iter( iter )
#       set_action_bar_sensitivity( GRISM::MENU_STOCK_ON_OPTS )
#       GRISM.menu_stock_sensitivity_opts( GRISM::MENU_STOCK_ON_OPTS )
#       yield :on, iter  if block_given?
#     end
# #    call_signal( 'has_selected', !(iter == nil) )
#   end

  def set_action_bar_sensitivity( opts={} )
    GRISM.btn_sensitivity( @libglade['folder_refresh_btn'], opts[:refresh] )
    GRISM.btn_sensitivity( @libglade['folder_add_btn'], opts[:add] )
    GRISM.btn_sensitivity( @libglade['folder_details_btn'], opts[:details] )
    GRISM.btn_sensitivity( @libglade['folder_chart_btn'], opts[:chart] )
    GRISM.btn_sensitivity( @libglade['folder_remove_btn'], opts[:remove] )
  end

  def set_store( store )
    @store = store
    @title_lbl.set_markup( '<b>' + @store.list_name + '</b>' )
    @libglade['folder_today'].text = "%.2f%%" % @store.today_total
    @libglade['folder_overall'].text = "%.2f%%" % @store.overall_total

    @fview.model = @store.liststore

    @store.signal_connect( 'name' ) {
      @title_lbl.set_markup( '<b>' + @store.list_name + '</b>' )
    }
    @store.signal_connect( 'description' ) {
    }
    @store.signal_connect( 'today' ) {
      @libglade['folder_today'].text = "%.2f%%" % @store.today_total
    }
    @store.signal_connect( 'overall' ) {
      @libglade['folder_overall'].text = "%.2f%%" % @store.overall_total
    }
  end

  def do_context_menu( view, event=nil )
    if event.kind_of?( Gdk::EventButton ) and event.button == 3
      #menu.popup(nil, nil, event.button, event.time)
      iter = view.selection.selected
      return if !iter
      context_menu_popup( iter )
    end
  end

end
