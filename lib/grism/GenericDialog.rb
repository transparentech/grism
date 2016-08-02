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

class GenericDialog

  attr_reader :libglade, :dialog
  attr_accessor :close

  def initialize( glade_root, libglade=nil )
    # Create the dialog.
    if !libglade
      @libglade = GladeXML.new( $FPATH + GRISM::GLADE, glade_root )
    else
      @libglade = libglade
    end
    @dialog = @libglade[glade_root]
  end

  def run( *args )
    if args.length > 0 and args[0].is_a?( Hash )
      targs = args[0]
    else
      targs = args
    end
    setup( targs )

    @close = true
    ret = nil

    begin
      @dialog.run do |response|
        case response
        when Gtk::Dialog::RESPONSE_OK
          ret = response_verification( targs, response_ok( targs ) )
        when Gtk::Dialog::RESPONSE_CANCEL
          ret = response_canceled( targs )
        else
          ret = response_other( response, targs )
        end
      end
    end while( !@close )

    before_hide( ret )
    @dialog.hide
    after_hide( ret )

    if block_given? and ret
      before_block( ret )
      yield ret
      after_block( ret )
    else
      return ret
    end

  end

  def force_hide()
    @dialog.hide
  end

  protected

  def setup( args )
  end

  def response_ok( args )
    @close = true
    nil
  end

  def response_verification( args, ret )
    ret
  end

  def response_canceled( args )
    @close = true
    nil
  end

  def response_other( response, args )
    @close = true
    nil
  end

  def before_hide( ret )
  end

  def after_hide( ret )
  end

  def before_block( ret )
  end

  def after_block( ret )
  end

end
