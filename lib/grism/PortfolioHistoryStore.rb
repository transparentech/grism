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

class PortfolioHistoryStore < GrismListStore

  @@columns = [
               [String, 'transType'],
               [String, 'transDate'],
               [Float, 'amount'],
               [String, 'desc'],
               [String, 'comment'],
               [Hash, 'typeColumns'],
               [PortfolioHistory, 'dbrow']
              ]

  def initialize( wplist_row )
    super( wplist_row, @@columns )

    self.list_type = 'portfolio_history'
    self.list_name = wplist_row.name
    self.list_desc = wplist_row.desc

    load()
  end

  def get_action_opts_for_iter( iter )
    if !iter
      GRISM::MENU_STOCK_OFF_OPTS
    else
      GRISM::MENU_STOCK_HIST_ON_OPTS
    end
  end

  # Reload the entire portfolio history from the database.
  def reload()
    @liststore.clear()
    load()
  end

  def add_row( date, transtype, amount, desc, comment )
    iter = @liststore.append()
    iter[dbrow] = PortfolioHistory.create( :w_p_list_id => @wplist.id )
    set_row( iter, date, transtype, amount, desc, comment, "" )
    save_row( iter ) if $PREFS['autosave']
  end

  def modify_row( iter, date, transtype, amount, desc, comment )
    set_row( iter, date, transtype, amount, desc, comment, nil )
    save_row( iter ) if $PREFS['autosave']
  end

  def remove_row( iter )
    return if !iter
    # Delete from table.
    iter[dbrow].destroy
    # Remove from store.
    @liststore.remove( iter )
    # Save if required.
    save() if $PREFS['autosave']
  end

  private

  #
  # Load the data from the database into the store.
  #
  def load()
    PortfolioHistory.
      find_all_by_w_p_list_id( @wplist.id,
                               :order => [:transdate,:id] ).each { |ph|
      iter = @liststore.append()
      iter[dbrow] = ph
      set_row( iter, ph.transdate.to_s, ph.transtype, 
               ph.amount, ph.desc, ph.comment, ph.typecolumns )
    }
  end
  #
  # Save every entry in the store into the database.
  #
  def save()
    ct = 0
    @liststore.each do |model, path, iter|
      if iter[dbrow]
        #ct += 1
        #iter[dbrow].pos = ct
        iter[dbrow].save
      end
    end
  end

  def set_row( iter, date, transtype, amt, descrip, cmt, typecolumns )
    iter[transDate] = date
    iter[transType] = transtype
    iter[amount] = amt
    iter[desc] = descrip
    iter[comment] = cmt
    iter[typeColumns] = typecolumns if typecolumns != nil
  end

  def save_row( iter )
    iter[dbrow].transdate = Date.parse( iter[transDate] )
    iter[dbrow].transtype = iter[transType]
    iter[dbrow].amount = iter[amount]
    iter[dbrow].desc = iter[desc]
    iter[dbrow].comment = iter[comment]
    iter[dbrow].typecolumns = iter[typeColumns]
    iter[dbrow].save
  end
end
