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

#require 'timeout'

class InfoBar
#  include Timeout

  @@DEFAULT_SLEEP = 0.1
  @@SLEEP_DELTA = 0.02

  attr_reader :running, :running_ct

  def initialize( progbar, statusbar )
    @mutex = Mutex.new
    @running = false
    @running_ct = 0
    @sleep = @@DEFAULT_SLEEP
    @pb = progbar
    @pb.pulse_step = 0.1
    @sb = statusbar
    @sbctx = @sb.get_context_id( "InfoBar" )
  end

  def run( txt, exception_block=nil )
    t = Thread.new( @pb, @sb ) do |pb, sb|
      id = 0
      @mutex.synchronize do 
        id = start( txt )
      end

      begin
        yield self
      rescue Exception => e
        if exception_block and exception_block.kind_of?( Proc )
          begin
            exception_block.call e
          rescue ex
            puts "InfoBar(#{txt}) exception_block: #{ex.message}"
          end
        else
          puts "InfoBar(#{txt}): #{$!}"
          puts "#{e.backtrace.join("\n")}"
        end
      end

      @mutex.synchronize do 
        stop( id )
      end

    end
  end

  private

  def start( startmsg )
    if !@running
      @running_ct = 0
      @running = true
      @pbt = Thread.new( @pb, @sb ) do |pb, sb|
        pb.fraction = 0
        while @running
          pb.pulse
          sleep( @sleep )
        end
        pb.fraction = 0
      end
    end

    id = 0
    @running_ct += 1
    compute_sleep
    id = @sb.push( @sbctx, startmsg )

    return id

  end

  def stop( id )
    @running_ct -= 1
    @running = false if @running_ct < 1
    compute_sleep
    @sb.remove( @sbctx, id )
  end

  def compute_sleep
    @sleep = @@DEFAULT_SLEEP - (@@SLEEP_DELTA * (@running_ct - 1))
    @sleep = @@SLEEP_DELTA if @sleep < @@SLEEP_DELTA
  end
end



if $0 == __FILE__
  require 'gtk2'
  Gtk.init
  pb = Gtk::ProgressBar.new
  sb = Gtk::Statusbar.new
  ib = InfoBar.new( pb, sb )
  win = Gtk::Window.new
  box = Gtk::VBox.new
  start = Gtk::Button.new( "Start" )
  start.signal_connect( "clicked" ) do |widg|
    puts "button-press-event : start"
    ib.run( "Running ##{ib.running_ct}" ) { |ib|
      puts "asdf.start"
      for x in 0..9
        break if !ib.running
        puts "asdf.#{x+1}"
        sleep( 1 )
      end
      puts "asdf.end"
    }
    puts "button-press-event : end"
  end
  box.pack_start( start )
  box.pack_start( pb )
  box.pack_start( sb )
  stop = Gtk::Button.new( "Stop" )
  stop.signal_connect( "clicked" ) do |widg|
    puts "key-press-event : start"
    ib.stop
    puts "key-press-event : end"
  end
  box.pack_start( stop )
  win.add( box )
  win.show_all
  win.signal_connect( "destroy" ) { 
    Gtk.main_quit
  }
  Gtk.main
end
