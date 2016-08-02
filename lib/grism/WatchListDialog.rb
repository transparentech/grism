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

class WatchListDialog < GenericDialog

  def initialize( libglade=nil )
    super( 'wldialog', libglade )

    @libglade['wldialog_usemarket'].signal_connect( 'toggled' ) do |usemarket|
      if usemarket.active?
        @libglade['wldialog_price_hbox'].sensitive = false
      else
        @libglade['wldialog_price_hbox'].sensitive = true
      end
    end

    # Set the icon of the 'important' check box.
    img = Gtk::Image.new( $FPATH + GRISM::IMPORTANT_TRUE_ICON_9 )
    img.set_padding( 4, 4 )
    @libglade['wldialog_important'].image = img
  end

  protected

  #
  # Returns a hash array with the following keys:
  #   :symbol, :date, :price, :comment, :important
  def response_ok( args )
    ret = {}
    ret[:symbol] = @libglade['wldialog_symbol'].text.upcase
    ret[:date] = sprintf( "%d-%d-%d", *@libglade['wldialog_date'].date )

    qt = nil
    if @libglade['wldialog_usemarket'].active?
      qt = YahooFinance::StandardQuote.new
      qt.load_quote( ret[:symbol] )
      ret[:price] = qt.lastTrade
    else
      ret[:price] = @libglade['wldialog_price'].value
    end

    ret[:comment] = @libglade['wldialog_comment'].buffer.text
    ret[:important] = @libglade['wldialog_important'].active?

    ret
  end

  def response_verification( args, ret )
    return ret if args[:wtype] == 'details'

    symbol = ret[:symbol]
    qt = YahooFinance.get_standard_quotes( symbol )[symbol]
    @close = true

    # Check if this is a valid symbol.
    if !qt.valid?
      warn_dialog( "<b>#{symbol} is not a valid symbol!</b>" )
      return ret
    end

    # Check if this symbol is already in the list.
    if args.length > 1
      if args[:store].has_symbol?( symbol )
        warn_dialog( "<b>#{symbol} is already in this WatchList!</b>" )
        return ret
      end
    end

    ret
  end

  def setup( args )
#    iter = nil
#    list = nil
#    iter = args[0] if args.length > 1
#    list = args[1] if args.length > 1

    if args[:wtype] == 'add'
      @libglade['wldialog_symbol'].text = ''
      @libglade['wldialog_symbol'].sensitive = true
      @libglade['wldialog_symbol'].focus = true
      @libglade['wldialog_important'].active = false
      @libglade['wldialog_usemarket'].active = true
      @libglade['wldialog_price'].value = 0
      @libglade['wldialog_comment'].buffer.text = ''
      d = Time.now
      @libglade['wldialog_date'].select_month( d.month, d.year )
      @libglade['wldialog_date'].select_day( d.day )
    else
      @libglade['wldialog_symbol'].text = 
        args[:iter][ args[:store].symbol ]
      @libglade['wldialog_symbol'].sensitive = false
      @libglade['wldialog_important'].active = 
        args[:iter][ args[:store].important ]
      @libglade['wldialog_usemarket'].active = false
      @libglade['wldialog_price'].value = 
        args[:iter][ args[:store].watchStart ]
      @libglade['wldialog_comment'].buffer.text = 
        args[:iter][ args[:store].comment ]
      @libglade['wldialog_comment'].focus = true
      year, month, day = args[:iter][ args[:store].date ].split( '-' )
      @libglade['wldialog_date'].select_month( month.to_i, year.to_i )
      @libglade['wldialog_date'].select_day( day.to_i )
    end
  end

  private

  def warn_dialog( markup )
    dialog = Gtk::MessageDialog.new( nil, Gtk::Dialog::MODAL,
                                     Gtk::MessageDialog::WARNING,
                                     Gtk::MessageDialog::BUTTONS_OK )
    dialog.markup = markup
    dialog.run
    dialog.hide
    @close = false
  end

end
