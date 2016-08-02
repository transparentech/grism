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

#
# Base class for all Mongoose database tables in Grism.
#
class GrismTable < Mongoose::Table
  def self.ensure( db )
    if !db.table_exists?( table_symbol() )
      db.create_table( table_symbol() ) do |tbl|
        create_table( tbl )
      end
      load_initial_data()
      false
    else
      true
    end
  end
  def self.table_symbol()
  end
  def self.create_table( tbl )
  end
  def self.load_initial_data()
  end
end

#
# Database table containing the list of watchlists and portfolios.
#
class WPList < GrismTable
  has_many :portfolios
  has_many :watchlists
  def self.table_symbol()
    :w_p_list
  end
  def self.create_table( tbl )
    tbl.add_indexed_column( :listtype, :integer )
    tbl.add_column( :name, :string )
    tbl.add_column( :desc, :string )
    tbl.add_column( :createdate, :date )
    tbl.add_column( :pos, :integer )
    # Each watchlist/portfolio will have its own set of preferences
    # stored in a hashtable.  The keys of the hashtable will be
    # different for a watchlist vs a portfolios.
    tbl.add_column( :prefs, :hash )
  end
end

#
# Database table containing the portfolio data.
#
class Portfolio < GrismTable
  belongs_to :w_p_list
  def self.table_symbol()
    :portfolio
  end
  def self.create_table( tbl )
    tbl.add_indexed_column( :w_p_list_id, :integer )
    tbl.add_column( :symbol, :string )
    tbl.add_column( :positiontype, :string )
    tbl.add_column( :buydate, :date )
    tbl.add_column( :buyprice, :float )
    tbl.add_column( :shares, :float )
    tbl.add_column( :costs, :float )
    tbl.add_column( :comment, :string )
    tbl.add_column( :pos, :integer )
  end
end

# 
# Database table containing the portfolio history data.
# 
class PortfolioHistory < GrismTable
  belongs_to :w_p_list
  def self.table_symbol()
    :portfolio_history
  end
  def self.create_table( tbl )
    tbl.add_indexed_column( :w_p_list_id, :integer )
    tbl.add_column( :transtype, :string )
    tbl.add_column( :transdate, :date )
    # Having 2 indexed columns caused problems with a "corrupted" db
    # after a crash. I'm changing it to a regular, non-indexed column
    # since we get around this bug and we don't absolutly need an
    # index here anyway.
    #tbl.add_indexed_column( :transdate, :date )
    tbl.add_column( :amount, :float )
    tbl.add_column( :desc, :string )
    tbl.add_column( :comment, :string )
    # Each type of entry (:transtype) may have a different set of
    # optional 'columns'.  These 'columns' are stored in this hash
    # table column.  For example: a row with :transtype == 'buy' might
    # have :typecolumns = {:buyprice,:risk,:stop-hi,:stop-low,
    # ...etc... }.
    tbl.add_column( :typecolumns, :hash )
  end
end

#
# Database table containing the watchlist data.
#
class Watchlist < GrismTable
  belongs_to :w_p_list
  def self.table_symbol()
    :watchlist
  end
  def self.create_table( tbl )
    tbl.add_indexed_column( :w_p_list_id, :integer )
    tbl.add_column( :symbol, :string )
    tbl.add_column( :adddate, :date )
    tbl.add_column( :watchstart, :float )
    tbl.add_column( :comment, :string )
    tbl.add_column( :important, :boolean )
    tbl.add_column( :pos, :integer )
  end
end
