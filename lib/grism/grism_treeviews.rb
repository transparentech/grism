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

# *************************************************************************
#
# Module containing methods helpful for setting-up Gtk TreeViews.
#
# *************************************************************************
module GrismTreeViews

  def addPixbufCol( tview, title, column, headerimage=nil )
    renderer = Gtk::CellRendererPixbuf.new
    col = Gtk::TreeViewColumn.new( title, renderer, :pixbuf => column )
    col.resizable = false
    if headerimage
      col.widget = Gtk::Image.new( $FPATH + headerimage )
      col.widget.show
    end
    if block_given?
      tview.signal_connect( 'button_press_event' ) { |tview,event| 
        if event.window == tview.bin_window
          path, vcol, x, y = tview.get_path_at_pos( event.x, event.y )
          if title == vcol.title
            iter = tview.model.get_iter( path )
            yield iter
          end
        end
      }
    end
    tview.append_column( col )
    return renderer
  end

  def addStringCol( tview, title, column, 
                    format="%s", resizable=nil, searchable=false )
    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new( title, renderer, :text => column )
    col.resizable = resizable if resizable
    if searchable
      tview.enable_search = true
      tview.search_column = column
      tview.set_search_equal_func() { |model, column, key, iter|
        #puts "searching for '#{key}' in '#{iter[column]}'"
        if iter[column] =~ /^#{key.upcase}/
          false
        else
          true
        end
      }
      #puts "searchable: #{title}:#{tview.enable_search?}"
    end
    col.set_cell_data_func( renderer ) do |col, renderer, model, iter|
      renderer.text = sprintf( format, iter[ column ] )
      if block_given?
        yield col, renderer, model, iter
      end
    end
    tview.append_column( col )
    return renderer
  end

  def addNumericCol( tview, title, column, format="%.4f", &block )
    renderer = addStringCol( tview, title, column, format, &block )
    renderer.xalign = 1.0
    return renderer
  end

  def movementColor( iter, renderer, column, bold=true )
    if iter[ column ] == 0
      renderer.foreground = 'black'
      renderer.weight = 400 unless !bold
    elsif iter[ column ] > 0
      renderer.foreground = 'darkgreen'
      renderer.weight = 700 unless !bold
    else
      renderer.foreground = 'red'
      renderer.weight = 700 unless !bold
    end
  end

end
