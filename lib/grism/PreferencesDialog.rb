
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

class PreferencesDialog < GenericDialog

  def initialize( libglade=nil )
    super( 'preferences', libglade )

    @libglade['pref_proxy_manual'].signal_connect( 'toggled' ) do |widget|
      #puts "toggled #{widget.active?} : #{@libglade['pref_proxy_manual'].active?}"
      if widget.active?
        @libglade['pref_proxy_manual_vbox'].sensitive = true
      else
        @libglade['pref_proxy_manual_vbox'].sensitive = false
      end
    end

    @libglade['pref_proxy_authenticate'].signal_connect( 'toggled' ) do |widget|
      #puts "AUTH - toggled #{widget.active?} : #{@libglade['pref_proxy_authenticating'].active?}"
      if widget.active?
        @libglade['pref_proxy_manual_authtable'].sensitive = true
      else
        @libglade['pref_proxy_manual_authtable'].sensitive = false
      end
    end

    @libglade['pref_proxy_authenticate'].active = false
    @libglade['pref_proxy_manual_authtable'].sensitive = false
    @libglade['pref_proxy_manual'].active = false
    @libglade['pref_proxy_manual_vbox'].sensitive = false

    @libglade['pref_timeout_open'].value = 5
    @libglade['pref_timeout_read'].value = 5
  end

  protected

  def response_ok( args )
    $PREFS['saveonexit'] = @libglade['pref_saveonexit'].active?
    $PREFS['autosave'] = @libglade['pref_autosave'].active?

    $PREFS['internet.host'] = @libglade['pref_proxy_host'].text.strip
    $PREFS['internet.port'] = @libglade['pref_proxy_port'].text.strip
    $PREFS['internet.username'] = @libglade['pref_proxy_username'].text.strip
    $PREFS['internet.password'] = 
      Base64.encode64( @libglade['pref_proxy_password'].text.strip ).strip

    if @libglade['pref_proxy_direct'].active?
      $PREFS['internet.type'] = 'direct'
    else
      $PREFS['internet.type'] = 'manual'
    end
    if @libglade['pref_proxy_authenticate'].active?
      $PREFS['internet.authenticate'] = 'yes'
    else
      $PREFS['internet.authenticate'] = 'no'
    end

    $PREFS['internet.open_timeout'] = @libglade['pref_timeout_open'].value.to_i
    $PREFS['internet.read_timeout'] = @libglade['pref_timeout_read'].value.to_i
  end

  def setup( args )
    @libglade['pref_saveonexit'].active = $PREFS['saveonexit']
    @libglade['pref_autosave'].active = $PREFS['autosave']

    if $PREFS['internet.username'] and $PREFS['internet.password']
      @libglade['pref_proxy_username'].text = $PREFS['internet.username']
      @libglade['pref_proxy_password'].text = 
        Base64.decode64( $PREFS['internet.password'] )
    end
    if $PREFS['internet.host'] and $PREFS['internet.port']
      @libglade['pref_proxy_host'].text = $PREFS['internet.host']
      @libglade['pref_proxy_port'].text = $PREFS['internet.port']
    end

    if $PREFS['internet.authenticate'] == 'yes'
      @libglade['pref_proxy_authenticate'].active = true
      @libglade['pref_proxy_manual_authtable'].sensitive = true
    else
      @libglade['pref_proxy_authenticate'].active = false
      @libglade['pref_proxy_manual_authtable'].sensitive = false
    end

    if $PREFS['internet.type'] == 'direct'
      @libglade['pref_proxy_direct'].active = true
      @libglade['pref_proxy_manual_vbox'].sensitive = false
    else
      @libglade['pref_proxy_manual'].active = true
      @libglade['pref_proxy_manual_vbox'].sensitive = true
    end

    @libglade['pref_timeout_open'].value = $PREFS['internet.open_timeout'].to_i
    @libglade['pref_timeout_read'].value = $PREFS['internet.read_timeout'].to_i
  end

end
