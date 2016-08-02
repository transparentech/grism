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

module GenericStore

  # Create an accessor method for each column.
  def init_column_accessors( columns )
    get_column_types( columns ).each_index do |index|
      instance_eval( "def #{columns[index][1]}() return #{index} end" )
    end
  end

  # Return an array of column names from the given array containing
  # type,name pairs.
  def get_column_names( columns )
    ret = []
    columns.each { |t,name| ret << name }
    return ret
  end

  # Return an array of column types from the given array containing
  # type,name pairs.
  def get_column_types( columns )
    ret = []
    columns.each { |t,name| ret << t }
    return ret
  end

end
