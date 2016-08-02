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

module GRISM

  def GRISM.init_db
    PREFS['db'] = HistoricalQuoteDatabase.new( PREFS['configdatadir'] )
  end

  def GRISM.init_mongoose_db( datapath )
    #db = Mongoose::Database.new( :path => 
    #File.expand_path( File.dirname( __FILE__  ) + '/../test' ) )

    # Initialize the Mongoose database.
    PREFS['mdb'] = Mongoose::Database.new( :path => datapath )

    # Ensure (check and create if necessary) the existance of the 3
    # database tables.
    WPList.ensure( PREFS['mdb'] )
    Watchlist.ensure( PREFS['mdb'] )
    PortfolioHistory.ensure( PREFS['mdb'] )
    need_to_import_db = !Portfolio.ensure( PREFS['mdb'] )

    #
    # Import the deprecated watchlist and portfolio CSV files into the
    # mongoose db.  We only need to do this if the databases did not
    # already exist, which should only be the first time Grism is run
    # after upgrading to v0.8.0.
    #
    if need_to_import_db

      puts "Upgrading Grism config to v0.8 format..."

      PREFS['lists'].each do |num|
        type = PREFS['lists-type'][num]
        file = PREFS['lists-file'][num]

        fn = File.join( PREFS['configdir'], File.basename( file ) )
        #fn = GRISM.validate_init_config_file( File.basename( file ) )
        puts "#{fn},#{type},#{num}"
        wplist_create( type, nil, nil ) { |wpl|
          position = 0
          File.open( fn, 'r' ) do |f|
            f.each_line do |line|
              # Get rid of any nasty line endings which otherwise get
              # left on and displayed.
              line.chomp!
              # Parse any meta-data (type,name,desc,etc) in the CSV file.
              if line =~ /^#~\s*(\w+)\s*=\s*(.*)\s*$/
                if $1 == 'list_name'
                  wpl.name = $2
                elsif $1 == 'list_desc'
                  wpl.desc = $2
                end
                #wpl.save
              end
              next if line =~ /^#/
              sline = CSV.parse_line( line.gsub( '~', "\n" ) )
              if type == 'portfolio'
                position += 1
                pf = Portfolio.create( :w_p_list_id => wpl.id,
                                       :symbol => sline[0].to_s,
                                       :positiontype => 'long',
                                       :buydate => Date.parse( sline[1].to_s ),
                                       :buyprice => sline[2].to_f,
                                       :shares => sline[3].to_f,
                                       :pos => position )
                pf.costs = sline[5].to_i if sline.size >= 6
                pf.comment = sline[6].to_s if sline.size >= 7
                pf.save
              elsif type == 'watchlist'
                position += 1
                wl = Watchlist.create( :w_p_list_id => wpl.id,
                                       :symbol => sline[0],
                                       :adddate => Date.parse( sline[1] ),
                                       :watchstart => sline[2].to_f,
                                       :comment => sline[3],
                                       :important => false )
                wl.important = ( sline[4] == 'true' ) if sline.size >= 5
                wl.save
              end
            end
          end
        }
      end
      puts 'done.'
    end
  end

  #
  # Set the ENV['http_proxy'] variable based on the
  # $PREFS['internet.*'] settings.  The ENV setting is used by the
  # yahoofinance module when sending requests.
  #
  def GRISM.init_proxy_settings
    if $PREFS['internet.type'] == 'manual'
      if /^\w+:\/\// === $PREFS['internet.host']
        uri = URI.parse( $PREFS['internet.host'] )
        $PREFS['internet.host'] = uri.host
      end

      p_str = nil
      if ( $PREFS['internet.port'] and $PREFS['internet.port'] != '' )
        p_str = ":#{$PREFS['internet.port']}"
      end

      a_str = nil
      if ( $PREFS['internet.authenticate'] and
           ( $PREFS['internet.username'] and 
             $PREFS['internet.username'] != '' ) and
           ( $PREFS['internet.password'] and 
             $PREFS['internet.password'] != '' ) )
        pwd = Base64.decode64( $PREFS['internet.password'] )
        a_str = "#{$PREFS['internet.username']}:#{pwd}@"
      end

      ENV['http_proxy'] = 
        "http://#{a_str}#{$PREFS['internet.host']}#{p_str}"

    else
      ENV['http_proxy'] = nil
    end
#    puts "ENV[http_proxy] = '#{ENV['http_proxy']}'"
  end

  def GRISM.shutdown
    if $PREFS['saveonexit']
      GRISM.save_all_lists
    end

    # Save the ~/.grism/grism.conf file.
    GRISM.save_user_config

    # Closing the mongoose DB is required in order to create the index
    # files.  If we don't call close() and the index files are not
    # created, we will get uncaught exceptions at the start of the
    # next run.
    $PREFS['mdb'].close()

    # Quit GTK.
    Gtk.main_quit
  end

  def GRISM.menu_folder_sensitivity( sen )
    PREFS['libglade']['refresh_mbtn'].sensitive = sen
    PREFS['libglade']['save_folder_mbtn'].sensitive = sen
    PREFS['libglade']['delete_folder_mbtn'].sensitive = sen
    PREFS['libglade']['properties_mbtn'].sensitive = sen
    PREFS['libglade']['add_item_mbtn'].sensitive = sen
  end
  def GRISM.menu_stock_sensitivity( sen )
    PREFS['libglade']['details_mbtn'].sensitive = sen
    PREFS['libglade']['chart_mbtn'].sensitive = sen
    PREFS['libglade']['remove_item_mbtn'].sensitive = sen
    PREFS['libglade']['moveto_mbtn'].sensitive = sen
    PREFS['libglade']['copyto_mbtn'].sensitive = sen
    PREFS['libglade']['split_mbtn'].sensitive = sen
    PREFS['libglade']['rename_mbtn'].sensitive = sen
  end

  def GRISM.menu_stock_sensitivity_opts( opts={} )
    lg = PREFS['libglade']
    GRISM.btn_sensitivity( lg['refresh_mbtn'], opts[:refresh] )
    GRISM.btn_sensitivity( lg['add_item_mbtn'], opts[:add] )
    GRISM.btn_sensitivity( lg['details_mbtn'], opts[:details] )
    GRISM.btn_sensitivity( lg['chart_mbtn'], opts[:chart] )
    GRISM.btn_sensitivity( lg['remove_item_mbtn'], opts[:remove] )
    GRISM.btn_sensitivity( lg['moveto_mbtn'], opts[:moveto] )
    GRISM.btn_sensitivity( lg['copyto_mbtn'], opts[:copyto] )
    GRISM.btn_sensitivity( lg['split_mbtn'], opts[:split] )
    GRISM.btn_sensitivity( lg['rename_mbtn'], opts[:rename] )
  end
  def GRISM.btn_sensitivity( mbtn, sen )
    if sen != nil 
      mbtn.sensitive = sen
    else
      mbtn.sensitive = false
    end
  end

  def GRISM.folder_action_activate
    if $PREFS['flist'].selected_type != FoldersStore::FOLDER_PARENT
      fdr = $PREFS['flist'].selected_folder
      yield fdr, fdr.selected unless !fdr
    end
  end

  def GRISM.wplist_create( ltype, name, desc )
    wplist = WPList.create( :listtype => ltype,
                            :createdate => Date.today, 
                            :name => name, :desc => desc, :prefs => {} )
    wplist.pos = wplist.id
    if block_given?
      yield wplist
    end
    wplist.save
    return wplist
  end

  def GRISM.new_watchlist_folder()
    $PREFS['folderdialog'].run( :name => 'New WatchList', 
                                :desc => 'My new watchlist', 
                                :type => 'WatchList',
                                :prefs => { } ) do |ret|
      wplist = wplist_create( 'watchlist', ret[:name], ret[:desc] )
      wp = new_wp_widget( wplist, FoldersStore::FOLDER_WATCHLIST )
      wp.set_preferences( ret[:prefs] )
      $PREFS['flist'].expand_watchlists()
      $PREFS['flist'].select_folder( wp )
    end
  end

  def GRISM.new_portfolio_folder()
    $PREFS['folderdialog'].run( :name => 'New Portfolio', 
                                :desc => 'My new portfolio', 
                                :type => 'Portfolio',
                                :prefs => { } ) do |ret|
      wplist = wplist_create( 'portfolio', ret[:name], ret[:desc] )
      wp = new_wp_widget( wplist, FoldersStore::FOLDER_PORTFOLIO )
      wp.set_preferences( ret[:prefs] )
      $PREFS['flist'].expand_portfolios()
      $PREFS['flist'].select_folder( wp )
    end
  end

  def GRISM.new_wp_widget( wplist_row, wptype )
    if wptype == FoldersStore::FOLDER_WATCHLIST
      wp = WatchListWidget.new( wplist_row )
    elsif wptype == FoldersStore::FOLDER_PORTFOLIO
      wp = PortfolioWidget.new( wplist_row )
    else
      # In this case, wplist_row is actually a string naming the widget.
      wp = ParentWidget.new( wplist_row )
    end
    $PREFS['folders'].add( wptype, wp )
    $PREFS['libglade']['notebook'].append_page( wp )
    wp.post_notebook_append()
#    wp.signal_connect( 'has_selected' ) do |bool|
#      menu_stock_sensitivity( bool )
#    end
    wp
  end

  def GRISM.delete_wplist_folder()
    wp = $PREFS['flist'].selected_folder
    dialog = Gtk::MessageDialog.new( nil, Gtk::Dialog::MODAL, 
                                     Gtk::MessageDialog::QUESTION, 
                                     Gtk::MessageDialog::BUTTONS_OK_CANCEL, 
                                     'Do you wish to permanently delete ' +
                                     'the following ' + 
                                     wp.folder_type + '?' )
    dialog.secondary_markup = 
      "<b>#{GRISM.html_escape( wp.store.list_name )}</b> " + 
      "- #{GRISM.html_escape( wp.store.list_desc )}"

    dialog.run do |response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        iter = $PREFS['flist'].selected_iter
        # Delete the elements from the portfolio or watchlist tables
        # and select the parent element in the tree.
        if wp.store.list_type == 'portfolio'
          Portfolio.delete_all() { |row| row.w_p_list_id == wp.store.wplist.id }
          PortfolioHistory.delete_all() { |row|
            row.w_p_list_id == wp.store.wplist.id
          }
          $PREFS['flist'].select_iter( $PREFS['folders'].pf_parent )
        else
          Watchlist.delete_all() { |row| row.w_p_list_id == wp.store.wplist.id }
          $PREFS['flist'].select_iter( $PREFS['folders'].wl_parent )
        end
        # Remove the notebook containing the widget.
        num = $PREFS['libglade']['notebook'].page_num( wp )
        $PREFS['libglade']['notebook'].remove_page( num )
        # Delete the element from the wplist database table.
        wp.store.wplist.destroy()
        # Delete the entry from the folders tree.
        $PREFS['folders'].delete( iter )
      else
        # Canceled.
      end
      dialog.hide
    end
  end

  def GRISM.switch_notebook_to_folder( widg )
    $PREFS['libglade']['notebook'].page = 
      $PREFS['libglade']['notebook'].page_num( widg )
  end

  def GRISM.yahoo_dialog_rescue( dialog ) 
    begin
      yield
    rescue Exception => e
      GRISM.yahoo_problem_dlg( e )
      dialog.force_hide
    end      
  end

  def GRISM.yahoo_problem_dlg( e, name=nil )
    if name
      msg = "#{name}: Problem getting quotes from Yahoo! Finance."
    else
      msg = "Problem getting quote from Yahoo! Finance."
    end
    dlg = Gtk::MessageDialog.new( nil, Gtk::Dialog::MODAL, 
                                  Gtk::MessageDialog::WARNING, 
                                  Gtk::MessageDialog::BUTTONS_OK, 
                                  msg )
    dlg.secondary_markup = e.message
    dlg.run
    dlg.hide
  end

  def GRISM.html_escape( s )
    s = s.to_s
    [['&', '&amp;'],['>', '&gt;'],['<', '&lt;']].each { |char, html| 
      s.gsub!( /#{char}/ ) { |m|
        m.size == 1 ? html : char
      } 
    }
    return s
  end

end

