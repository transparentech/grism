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

module GRISM

  GLADE = "/grism.glade"
  REFRESH_TIMEOUT = 5

  PORTFOLIO_ICON_16       = "/images/stock_form-currency-field.png"
  PORTFOLIO_ICON_24       = "/images/stock_form-currency-field-24x24.png"

  WATCHLIST_ICON_16       = "/images/stock_macro-watch-variable.png"
  WATCHLIST_ICON_24       = "/images/stock_macro-watch-variable-24x24.png"

  CHARTING_ICON_16        = "/images/stock_chart-autoformat.png"
  CHARTING_ICON_24        = "/images/stock_chart-autoformat-24x24.png"

  EXTENDEDVIEW_ICON_24    = "/images/stock_zoom-page.png"
  CASH_ICON_24            = "/images/gnome-finance.png"
  HISTORY_ICON_24         = "/images/stock_new-address-book.png"
  CHARTEXPORT_ICON_16     = "/images/stock_export.png"
  GRISMFOLDERTYPE_ICON_32 = "/images/stock_chart.png"

  PREFS_GENERAL_ICON_32   = "/images/stock_autopilot.png"
  PREFS_QUOTES_ICON_32    = "/images/stock_help-agent.png"
  PREFS_INTERNET_ICON_32  = "/images/stock_internet.png"

  IMPORTANT_TRUE_ICON_9   = '/images/star.png'
  IMPORTANT_FALSE_ICON_9  = '/images/star-no.png'

  ABOUT_LOGO              = '/images/bull-logo-100x100.png'

  GRISM_WINDOW_ICON_16    = '/images/bull-icon-16x16.png'
  GRISM_WINDOW_ICON_32    = '/images/bull-icon-32x32.png'
  GRISM_WINDOW_ICON_48    = '/images/bull-icon-48x48.png'

  #
  # Menu options.
  #

  MENU_STOCK_OFF_OPTS = { :refresh => true, :add => true }
  MENU_STOCK_NO_SELECT_OPTS = { :refresh => true, :add => true }
  MENU_STOCK_ON_OPTS = { 
    :refresh => true, :add => true, 
    :details => true, :chart => true, :remove => true,
    :moveto => true, :copyto => true, :split => true, :rename => true
  }
  MENU_STOCK_HIST_ON_OPTS = { :refresh => true, :add => true, :details => true, :remove => true }

end
