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

class PortfolioWidget < WPListWidget

  attr_reader :hist_store

  def initialize( wplist_row )
    super()

    set_store( PortfolioStore.new( wplist_row ) )
    # Set the portfolio history store.
    @hist_store = PortfolioHistoryStore.new( wplist_row )
    @fview_ext.model = @hist_store.liststore
    @selected_store = @store

    # Set the specific icons for the toolbar.
    @libglade['folder_view_pf_sep'].show
    @libglade['folder_pf_view'].icon_widget =
      Gtk::Image.new( $FPATH + GRISM::PORTFOLIO_ICON_24 )
    @libglade['folder_pf_view'].show_all
    @libglade['folder_hist_view'].icon_widget =
      Gtk::Image.new( $FPATH + GRISM::HISTORY_ICON_24 )
    @libglade['folder_hist_view'].show_all
    @libglade['folder_other_sep'].show
    @libglade['folder_cash_btn'].icon_widget = 
      Gtk::Image.new( $FPATH + GRISM::CASH_ICON_24 )
    @libglade['folder_cash_btn'].show_all
    @libglade['folder_cash_btn'].signal_connect( 'clicked' ) { 
      cash_transaction()
    }

    # Manage the cash management toolbar button.
    set_cash_btn_sensitivity()
    @store.signal_connect( 'usecash_changed' ) { 
      set_cash_btn_sensitivity()
    }

    # Reload the history store on history changes.
    @store.signal_connect( 'history_changed' ) { |ph_hist|
      #puts "PW - ph_hist=#{ph_hist}"
      @hist_store.reload
    }

    signal_connect( 'hist_view_shown' ) { 
      #puts "Showing hist view."
#      set_hist_actions_sensitive()
      @selected_store = @hist_store
      selection_changed_in_fview_ext( selected() )
    }
    signal_connect( 'pf_view_shown' ) { 
      #puts "Showing pf view."
#      set_portfolio_actions_sensitive()
      @selected_store = @store
      selection_changed_in_fview( selected() )
    }

    # Hide the Watchlist specific toolbar buttons.
    @libglade['folder_view_sep'].hide
    @libglade['folder_std_view'].hide
    @libglade['folder_ext_view'].hide

    #
    # Portfolio list.
    #

    addStringCol( @fview, 'Symbol', @store.symbol ) do 
      |col, renderer, model, iter|
      renderIter( iter, renderer )
    end
    renderer = addNumericCol( @fview, 'Shares', @store.shares ) do
      |col, renderer, model, iter|
      renderIterNoCashTotal( iter, renderer )
      #renderer.text = "-#{renderer.text}" if iter[@store.ptype] == 'short'
    end
    renderer.editable = true
    renderer.signal_connect( 'edited' ) do |rend, path, text|
      editPortfolioColumn( @store.shares, path, text.to_f )
    end
    renderer = addNumericCol( @fview, 'Price', @store.price ) do
      |col, renderer, model, iter|
      renderIterNoCashTotal( iter, renderer )
    end
    renderer.editable = true
    renderer.signal_connect( 'edited' ) do |rend, path, text|
      editPortfolioColumn( @store.price, path, text.to_f )
    end
    addNumericCol( @fview, 'Value', @store.value, '%.2f' ) do
      |col, renderer, model, iter|
      renderIter( iter, renderer )
#      renderIterNoCash( iter, renderer )
    end
    renderer = addNumericCol( @fview, 'Last', 
                              @store.lastTrade ) do
      |col, renderer, model, iter|
      renderIterNoCashTotal( iter, renderer )
    end
    renderer.editable = true
    renderer.signal_connect( 'edited' ) do |rend, path, text|
      editPortfolioColumn( @store.lastTrade, path, text.to_f )
    end

    addNumericCol( @fview, 'Today', @store.change ) do
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.change )
      renderIterNoCashTotal( iter, renderer )
    end
    addNumericCol( @fview, 'Today %', @store.percent, '%.2f%%' ) do 
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.percent )
      renderIterNoCash( iter, renderer )
    end
    addNumericCol( @fview, 'Today $', @store.valueChange, '%.2f' ) do 
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.valueChange )
      renderIterNoCash( iter, renderer )
    end

    addNumericCol( @fview, 'Current Value', @store.currentValue, '%.2f' ) do
      |col, renderer, model, iter|
      renderIter( iter, renderer )
    end
    addNumericCol( @fview, 'Overall', @store.overallChange ) do
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.overallChange )
      renderIterNoCashTotal( iter, renderer )
    end
    addNumericCol( @fview, 'Overall %', @store.overallPercent, '%.2f%%' ) do
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.overallPercent )
      renderIterNoCash( iter, renderer )
    end
    addNumericCol( @fview, 'Overall $', @store.overallValueChange ) do
      |col, renderer, model, iter|
      movementColor( iter, renderer, @store.overallValueChange, false )
      renderIterNoCash( iter, renderer )
    end

#
# The commented columns here will probably be added back in a later.
# I would like to make which columns are displayed configurable.
#

#     addNumericCol( @fview, 'Less Costs', 
#                    @store.overallPercentAfterCosts, '%.2f%%' ) do
#       |col, renderer, model, iter|
#       movementColor( iter, renderer, @store.overallPercentAfterCosts )
#       portfolioColumn( iter, renderer )
#     end
#     addNumericCol( @fview, 'Less Costs', @store.overallValueChangeAfterCosts ) do
#       |col, renderer, model, iter|
#       movementColor( iter, renderer, @store.overallValueChangeAfterCosts, false )
#       portfolioColumn( iter, renderer, @store.overallValueChangeAfterCosts )
#     end
#     renderer = addNumericCol( @fview, 'Costs', @store.costs ) do 
#       |col, renderer, model, iter|
#       portfolioColumn( iter, renderer, @store.costs )
#     end
#     renderer.editable = true
#     renderer.signal_connect( 'edited' ) do |rend, path, text|
#       editPortfolioColumn( @store.costs, path, text.to_f )
#     end
#     addNumericCol( @fview, 'Cost %', @store.costPercent, '%.2f%%' ) do 
#       |col, renderer, model, iter|
#       portfolioColumn( iter, renderer, @store.costPercent )
#     end

    #
    # PortfolioHistory table.
    #
    addStringCol( @fview_ext, 'Date', @hist_store.transDate ) do 
      |col, renderer, model, iter|
      renderIter( iter, renderer )
    end
    addStringCol( @fview_ext, 'Type', @hist_store.transType ) do 
      |col, renderer, model, iter|
      renderIter( iter, renderer )
    end
    addNumericCol( @fview_ext, 'Amount', @hist_store.amount ) do
      |col, renderer, model, iter|
      movementColor( iter, renderer, @hist_store.amount )
      renderIterNoCashTotal( iter, renderer )
    end
    addStringCol( @fview_ext, 'Description', @hist_store.desc ) do 
      |col, renderer, model, iter|
      renderIter( iter, renderer )
    end

  end

  def folder_type
    'Portfolio'
  end

  def icon_name
    GRISM::PORTFOLIO_ICON_16
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
    $PREFS['infobar'].run( 'Updating portfolio ...', errblk ) do |ib|
      @store.refresh
    end
  end
  def add_element
    if @selected_store == @store
      GRISM.yahoo_dialog_rescue( $PREFS['pfdialog'] ) { 
        $PREFS['pfdialog'].run( :type => 'add', 
                                :prefs => @store.get_preferences() ) do |ret|
          @store.add_row( ret[:symbol], ret[:positiontype], ret[:date],
                          ret[:price], ret[:shares], 
                          ret[:costs], ret[:comment] )
        end
      }
    else
      $PREFS['pfhistdialog'].run( :transtype => 'buy',
                                  :amount => 0,
                                  :desc => "",
                                  :comment => "" ) do |ret|
        @hist_store.add_row( ret[:date], ret[:transtype], 
                             ret[:amount], ret[:desc], ret[:comment])
      end
    end
  end
  def details( iter )
    if @selected_store == @store
      if !@store.static_row?( iter )
        GRISM.yahoo_dialog_rescue( $PREFS['pfdialog'] ) { 
          $PREFS['pfdialog'].run( :type => 'modify', 
                                  :iter => iter, 
                                  :store => @store,
                                  :prefs => @store.get_preferences() ) do |ret|
            @store.modify_row( iter, ret[:positiontype], ret[:date], 
                               ret[:price], ret[:shares], 
                               ret[:costs], ret[:comment] )
          end
        }
      end
    else
      $PREFS['pfhistdialog'].run( :date => iter[@hist_store.transDate],
                                  :transtype => iter[@hist_store.transType],
                                  :amount => iter[@hist_store.amount],
                                  :desc => iter[@hist_store.desc],
                                  :comment => iter[@hist_store.comment] ) do |ret|
        @hist_store.modify_row( iter, ret[:date], ret[:transtype], 
                                ret[:amount], ret[:desc], ret[:comment] )
      end
    end
  end
  def remove_element( iter )
    if @selected_store == @store
      if !@store.static_row?( iter )
        GRISM.yahoo_dialog_rescue( $PREFS['pfdialog'] ) { 
          $PREFS['pfdialog'].run( :type => 'remove', 
                                  :iter => iter, 
                                  :store => @store,
                                  :prefs => @store.get_preferences() ) do |ret|
            @store.remove_row( iter, ret[:positiontype], ret[:date],
                               ret[:price], ret[:shares],
                               ret[:costs], ret[:comment] )
          end
        }
      end
    else
      dialog = Gtk::MessageDialog.new( nil, Gtk::Dialog::MODAL, 
                                       Gtk::MessageDialog::QUESTION, 
                                       Gtk::MessageDialog::BUTTONS_OK_CANCEL, 
                                       'Do you wish to remove the following ' +
                                       'historical record?' )
      dialog.secondary_markup = 
        "#{GRISM.html_escape( iter[@hist_store.transDate] )} " + 
        "; #{GRISM.html_escape( iter[@hist_store.transType] )} " +
        "; #{GRISM.html_escape( iter[@hist_store.amount] )} " +
        "; #{GRISM.html_escape( iter[@hist_store.desc] )} "


      dialog.run do |response|
        case response
        when Gtk::Dialog::RESPONSE_OK
          @hist_store.remove_row( iter )
        else
          # Canceled.
        end
      end
      dialog.hide
    end
  end
  def moveto( iter )
    $PREFS['mvcpdialog'].run( FoldersStore::FOLDER_PORTFOLIO ) do |ret|
      ret[1].store.add_row_from_iter( iter )
      @store.remove_row( iter )
      #puts "ok: move to->#{ret[0]} : #{@store.iter_to_csv( iter )}"
    end
  end
  def copyto( iter )
    $PREFS['mvcpdialog'].run( FoldersStore::FOLDER_PORTFOLIO ) do |ret|
      ret[1].store.add_row_from_iter( iter )
      #puts "ok: move to->#{ret[0]} : #{@store.iter_to_csv( iter )}"
    end
  end
  def split( iter )
    $PREFS['splitdialog'].run do |x, y, log|
      @store.split( iter, x, y, log )#ret[0], ret[1], ret[2] )
    end
  end
  def rename( iter )
    $PREFS['renamedialog'].run( :iter => iter,
                                :store => @store ) do |newname, log|
      @store.rename( iter, newname, log )
    end
  end
#   def switch_to_me()
#     # if fview_hist showing
#     #   if selection in fview_hist
#     #     change menu actives to HIST
#     #   else
#     #     change menu actives to NO_SELECT
#     # elsif fview showing
#     #   if selection in fview
#     #     change menu actives to ON
#     #   else
#     #     change menu actives to NO_SELECT
#     # end

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

#   def selection_changed_in_fview( iter )
#     super( iter )
#   end
#   def selection_changed_in_fview_ext( iter )
#     super( iter )
#   end

  def get_action_opts_for_iter( iter )
    @selected_store.get_action_opts_for_iter( iter )
  end

#   def set_hist_actions_sensitive()
#     actionSensitivityOpts( GRISM::MENU_STOCK_HIST_OPTS )
#     GRISM.menu_stock_sensitivity_opts( GRISM::MENU_STOCK_HIST_OPTS )
#   end

#   def set_portfolio_actions_sensitive()
#     if ( selected() )
#       actionSensitivity( true )
#     else
#       actionSensitivity( false )
#     end
#   end

  def set_cash_btn_sensitivity()
    if ( !@store.get_preferences().has_key?( :usecash ) or
         !@store.get_preferences()[:usecash] )
      @libglade['folder_cash_btn'].sensitive = false
    else
      @libglade['folder_cash_btn'].sensitive = true
    end
  end

  def cash_transaction()
    $PREFS['cashdialog'].run( @store.cash() ) do |ttype, amount, date, comment|
      @store.cash_transfer( ttype, amount, date, "cash transfer", comment )
    end
  end

  def renderIter( iter, renderer )
    if @store.total_row?( iter )
      renderer.weight = 700
    else
      renderer.weight = 400
    end
  end
  def renderIterNoCash( iter, renderer )
    renderIter( iter, renderer )
    renderer.text = '' if @store.cash_row?( iter )
  end
  def renderIterNoTotal( iter, renderer )
    renderIter( iter, renderer )
    renderer.text = '' if @store.total_row?( iter )
  end
  def renderIterNoCashTotal( iter, renderer )
    renderIter( iter, renderer )
    renderer.text = '' if @store.static_row?( iter )
  end

  def editPortfolioColumn( column, path, val )
    @store.set_row_column( path, column, val )
  end

end
