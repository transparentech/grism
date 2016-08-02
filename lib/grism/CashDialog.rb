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

class CashDialog < GenericDialog

  def initialize( libglade=nil )
    super( 'cashdialog', libglade )
  end

  protected

  def response_ok( args )
    ret = []
    if @libglade['cashdialog_deposit'].active?
      ret << 'deposit'
      ret << @libglade['cashdialog_amount'].value
    else
      ret << 'withdraw'
      ret << ( -@libglade['cashdialog_amount'].value )
    end
    ret << sprintf( "%d-%d-%d", *@libglade["cashdialog_date"].date )
    ret << @libglade['cashdialog_comment'].buffer.text
    ret
  end

  def setup( args )
    @libglade['cashdialog_balance'].markup = "<b><big>#{args[0].to_s}</big></b>"
    @libglade['cashdialog_deposit'].active = true
    @libglade['cashdialog_withdraw'].active = false
    @libglade['cashdialog_amount'].value = 0
    # @libgalde['cashdialog_amount'].select_region( 0, -1 )
    # @libgalde['cashdialog_amount'].grab_focus
    d = Time.now
    @libglade["cashdialog_date"].select_month( d.month, d.year )
    @libglade["cashdialog_date"].select_day( d.day )
    @libglade['cashdialog_comment'].buffer.text = ''
  end

end
