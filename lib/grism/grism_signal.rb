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

module GrismSignal

  @grismsignals = nil

  def init_signals( signals )
    @grismsignals ||= {}
    signals.each do |sig|
      @grismsignals[sig] = []
    end
  end

  def add_signal( sig )
    # do error checking here?  already exists?
    @grismsignals[sig] = []
  end

  def signal_connect( sig, &block )
    if @grismsignals.has_key?( sig )
      @grismsignals[sig] << block
    else
      super( sig, &block )
    end
  end

  protected 

  def call_signal( sig, *args )
    @grismsignals[sig].each do |proc|
      if args.length > 0
        proc.call( *args )
      else
        proc.call( self )
      end
    end
  end

end
