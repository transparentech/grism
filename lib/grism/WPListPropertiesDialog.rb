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

class WPListPropertiesDialog < GenericDialog

  def initialize( libglade=nil )
    super( 'wplistdialog', libglade )

    @namecache = ''
    @desccache = ''
    @typecache = ''

    @libglade['wplistdialog'].transient_for = @libglade['grism']

    # What I wanted the window to do was to resize when the expander
    # is opened or closed.  It was easy to get it to expand on open,
    # but shrinking on close never worked.  The signals below were
    # attempts at getting shrinking to work.
    #
    # The only way I found was to make the dialog resizable=false.
    # Then the expanding/shrinking worked without any additional code.
    # So now the window is not resizable, but I don't think that's a
    # big issue.
    #
#     @libglade['wplistdialog_advexpander'].
#       signal_connect_after( 'activate' ) { |exp|
#       puts "activate;exp=#{exp.expanded?}"
#     }
#     @libglade['wplistdialog_advnotebook'].
#       signal_connect_after( 'unmap' ) { |exp|
#       puts 'unmap;'
#       @libglade['wplistdialog'].
#         resize( *@libglade['wplistdialog'].size_request() )
#     }
  end

  protected

  def response_ok( args )
    ret = { }
    nm = @libglade['wplistdialog_name'].text
    ds = @libglade['wplistdialog_desc'].buffer.text
    nm = @namecache unless nm.strip.length > 0
    ds = @desccache unless ds.strip.length > 0
    ret[:name] = nm.strip
    ret[:desc] = ds.strip

    prefs = { }
    if ( @typecache == 'WatchList' )
    else
      prefs[:usecash] = @libglade['wplistdialog_pf_usecash'].active?
      prefs[:defcosts] = @libglade['wplistdialog_pf_defcosts'].value
    end
    ret[:prefs] = prefs

    ret
  end

  def setup( args )
    # @libglade['wplistdialog'].resize( *thisdlg.size_request() )

    @libglade['wplistdialog_name'].grab_focus
    @libglade['wplistdialog_name'].text = args[:name]
    @libglade['wplistdialog_name'].select_region( 0, -1 )
    @libglade['wplistdialog_desc'].buffer.text = args[:desc]
    @libglade['wplistdialog'].title = args[:type] + ' Properties'

    @namecache = args[:name]
    @desccache = args[:desc]
    @typecache = args[:type]

    if ( @typecache == 'WatchList' )
      @libglade['wplistdialog_advnotebook'].set_page( 0 )
    else
      @libglade['wplistdialog_advnotebook'].set_page( 1 )
      @libglade['wplistdialog_pf_usecash'].active = false
      @libglade['wplistdialog_pf_defcosts'].value = 10
      if args[:prefs].has_key?( :usecash )
        @libglade['wplistdialog_pf_usecash'].active = args[:prefs][:usecash]
      end
      if args[:prefs].has_key?( :defcosts )
        @libglade['wplistdialog_pf_defcosts'].value = args[:prefs][:defcosts]
      end
    end
   end

  def after_hide( ret )
    @libglade['wplistdialog_advexpander'].expanded = false
  end
end
