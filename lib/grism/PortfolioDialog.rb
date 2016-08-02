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

class PortfolioDialog < GenericDialog

  def initialize( libglade=nil )
    super( 'pfdialog', libglade )

    @libglade['pfdialog_priceusemarket'].signal_connect( 'toggled' ) do 
      |usemarket|

      if usemarket.active?
        @libglade['pfdialog_price_hbox'].sensitive = false
      else
        @libglade['pfdialog_price_hbox'].sensitive = true
      end
    end

    # Values cached during setup.
    @symbol = nil
    @ptype = nil
  end

  protected

  #
  # Returns a hash with the following keys::
  #   :symbol, :transactiontype, :date, :price, :shares, :costs, :comment
  #
  def response_ok( args )
    ret = { }

    case args[:type]
    when 'add'
      ret[:symbol] = @libglade['pfdialog_buy_symbol'].text.upcase

      if @libglade['pfdialog_buy_buy'].active?
        ret[:positiontype] = 'long'
      else
        ret[:positiontype] = 'short'
      end

      if @libglade['pfdialog_priceusemarket'].active?
        qt = YahooFinance::StandardQuote.new
        qt.load_quote( ret[:symbol] )
        ret[:price] = qt.lastTrade
      else
        ret[:price] = @libglade['pfdialog_price'].value
      end

    when 'modify', 'remove'
      ret[:symbol] = @symbol
      ret[:positiontype] = @ptype
      ret[:price] = @libglade['pfdialog_price'].value
    end

    ret[:date] = sprintf( "%d-%02d-%02d", *@libglade['pfdialog_date'].date )
    if ( ret[:positiontype] == 'long' )
      ret[:shares] = @libglade['pfdialog_shares'].value
    else
      ret[:shares] = -@libglade['pfdialog_shares'].value
    end
    ret[:costs] = @libglade['pfdialog_costs'].value
    ret[:comment] = @libglade['pfdialog_comment'].buffer.text
    ret
  end

  def response_verification( args, ret )
    #puts "PD.r_v : #{ret.to_s}"
    case args[:type]
    when 'add'
      symbol = ret[:symbol]
      qt = YahooFinance.get_standard_quotes( symbol )[symbol]
      @close = true
      if !qt.valid?
        dialog = Gtk::MessageDialog.new( @libglade['pfdialog'], 
                                         Gtk::Dialog::MODAL,
                                         Gtk::MessageDialog::WARNING,
                                         Gtk::MessageDialog::BUTTONS_OK )
        dialog.markup = "\'<b>#{symbol}</b>\' is not a valid symbol!"
        dialog.run
        dialog.hide
        @close = false
      end
    end
    ret
  end

  #
  # Setup the dialog with initial values based on the situation.
  # 
  # args should contain: 
  #  :type  - string with the type of usage {add,remove,modify}
  #  :prefs - 
  #  :iter  - only for ptype=modify|remove; iter of entry.
  #  :store - only for ptype=modify|remove; list containing entry.
  #
  def setup( args )
#    iter = args[1] if args.length > 1
#    list = args[2] if args.length > 2

    case args[:type]
    when 'add'
      @symbol = ''
      @libglade['pfdialog'].title = 'Add to Portfolio'
      @libglade['pfdialog_notebook'].page = 0
      @libglade['pfdialog_buy_symbol'].text = ''
      @libglade['pfdialog_buy_symbol'].sensitive = true
      @libglade['pfdialog_buy_symbol'].focus = true

      @libglade['pfdialog_buy_buy'].active = true
      @libglade['pfdialog_buy_sellshort'].active = false

      @libglade['pfdialog_shares'].value = 100
      @libglade['pfdialog_priceusemarket'].active = true
      @libglade['pfdialog_priceusemarket'].show
      @libglade['pfdialog_price_lbl'].show
      @libglade['pfdialog_price'].value = 1
      set_calendar( Time.now() )
      if ( args[:prefs].has_key?( :defcosts ) )
        @libglade['pfdialog_costs'].value = args[:prefs][:defcosts]
      else
        @libglade['pfdialog_costs'].value = 10
      end
      @libglade['pfdialog_comment'].buffer.text = ''

    when 'modify'
      @symbol = args[:iter][args[:store].symbol]
      @ptype = args[:iter][args[:store].ptype]
      @libglade['pfdialog'].title = 'Portfolio Entry'
      @libglade['pfdialog_notebook'].page = 1
      @libglade['pfdialog_modify_symbol'].markup = 
        "<b><big>#{args[:iter][ args[:store].symbol ]}</big></b>"
      if ( args[:iter][ args[:store].ptype ] == 'long' )
        @libglade['pfdialog_modify_type'].markup = 
          "<b><big>LONG</big></b>"
      else
        @libglade['pfdialog_modify_type'].markup = 
          "<b><big>SHORT</big></b>"
      end
      set_shares_priceusemarket_costs( args[:iter], args[:store] )
      set_calendar( args[:iter][ args[:store].date ] )
      @libglade['pfdialog_price'].value = args[:iter][ args[:store].price ]
      @libglade['pfdialog_comment'].buffer.text = 
        args[:iter][ args[:store].comment ]

    when 'remove'
      @symbol = args[:iter][args[:store].symbol]
      @ptype = args[:iter][args[:store].ptype]
      @libglade['pfdialog'].title = 'Remove from Portfolio'
      @libglade['pfdialog_notebook'].page = 2
      @libglade['pfdialog_sell_symbol'].markup = 
        "<b><big>#{args[:iter][ args[:store].symbol ]}</big></b>"
      if ( args[:iter][ args[:store].ptype ] == 'long' )
        @libglade['pfdialog_sell_type'].markup = 
          "<b><big>SELL</big></b>"
      else
        @libglade['pfdialog_sell_type'].markup = 
          "<b><big>BUY TO COVER</big></b>"
      end
      set_shares_priceusemarket_costs( args[:iter], args[:store] )
      set_calendar( Time.now )
      @libglade['pfdialog_price'].value = args[:iter][ args[:store].lastTrade ]
      @libglade['pfdialog_comment'].buffer.text = ''
    end
  end

  def set_shares_priceusemarket_costs( iter, store )
    if ( iter[ store.ptype ] == 'long' )
      @libglade['pfdialog_shares'].value = iter[ store.shares ]
    else
      @libglade['pfdialog_shares'].value = -iter[ store.shares ]
    end
    @libglade['pfdialog_shares'].focus = true
    @libglade['pfdialog_priceusemarket'].active = false
    @libglade['pfdialog_priceusemarket'].hide
    @libglade['pfdialog_price_lbl'].hide
    @libglade['pfdialog_costs'].value = iter[ store.costs ]
  end

  def set_calendar( date )
    if ( date.instance_of?( String ) )
      year, month, day = date.split( '-' )
      @libglade['pfdialog_date'].select_month( month.to_i, year.to_i )
      @libglade['pfdialog_date'].select_day( day.to_i )
    elsif ( date.instance_of?( Time ) )
      @libglade['pfdialog_date'].select_month( date.month, date.year )
      @libglade['pfdialog_date'].select_day( date.day )
    end
  end
end
