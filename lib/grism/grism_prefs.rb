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
# Configuration file handling.
#
# *************************************************************************
module GRISM

  # Hash of configs/preferences.
  PREFS = Hash.new
  # Preferences to write into config file on save.
  PREFS_SAVE = %w( autosave saveonexit grism.width grism.height folderslist.width folderslist.watchlists.expanded folderslist.portfolios.expanded folderslist.selected internet.type internet.host internet.port internet.authenticate internet.username internet.password internet.open_timeout internet.read_timeout )

  DEFAULT_CONFIG_FILE = "grism.config"
#  DEFAULT_WATCHLIST_FILE = "watchlist.csv"
#  DEFAULT_PORTFOLIO_FILE = "portfolio.csv"

  DEFAULT_CONFIG_FILE_CONTENTS = %Q/# GRISM configuration file (grism.config).
/

  # Set the default preference values.
  def GRISM.init_prefs()
    PREFS['saveonexit'] = true
    PREFS['autosave'] = true
    PREFS['grism.width'] = nil
    PREFS['grism.height'] = nil
    PREFS['folderslist.width'] = nil
    PREFS['folderslist.watchlists.expanded'] = nil
    PREFS['folderslist.portfolios.expanded'] = nil
    PREFS['folderslist.selected'] = nil
    PREFS['internet.type'] = 'direct'
    PREFS['internet.open_timeout'] = 5
    PREFS['internet.read_timeout'] = 5

    # Watchlist numbers from config file.  These are obsolete.
    PREFS["lists"] = []
    PREFS["lists-type"] = {}
    PREFS["lists-file"] = {}
    PREFS["lists-name"] = {}

    # WatchlistWidget objects. This is obsolete.
    PREFS["lists-wdg"] = []
    return PREFS
  end

  def GRISM.config_dir()
    if PLATFORM.match("mswin")
      PREFS['platform'] = 'windows'
      # As of v0.9.0, we are using this path for GRISM config on windows.
      # The APPDATA environment variable is available on both XP and Vista.
      #
      # XP    => c:/Documents and Settings/nick/Application Data
      # Vista => c:/Users/nick/AppData/Roaming
      #
      gdir_09 = "#{ENV["APPDATA"]}/GRISM"
      # However, we support the old version too if someone has already
      # been using it.
      gdir_08 = "#{ENV["USERPROFILE"]}/GRISM"
      if File.exist?( gdir_09 )
        # The v0.9 location has priority.
        return gdir_09
      elsif File.exist?( gdir_08 )
        # Then comes the old/deprecated v0.8 version.
        return gdir_08
      else
        # For new installations, use the new 0.9 directory.
        return gdir_09
      end
    else
      PREFS['platform'] = 'unix'
      return "#{ENV["HOME"]}/.grism"
      # Testing dir.
      #return "/usr/local/tmp/.grism"
    end
  end

  #
  # Verify/Setup the user's config directory.
  #
  def GRISM.init_config_dir( dir=nil )
    dir = config_dir if !dir
    PREFS["configdir"] = File.expand_path( dir )
    PREFS["configdatadir"] = PREFS["configdir"] + "/data"
    PREFS["configchartsdir"] = PREFS["configdir"] + "/charts"

    validate_init_config_dir( PREFS["configdir"] )
    validate_init_config_dir( PREFS["configdatadir"] )
    validate_init_config_dir( PREFS["configchartsdir"] )

    validate_init_config_file( DEFAULT_CONFIG_FILE ) do |file|
      file.write DEFAULT_CONFIG_FILE_CONTENTS
    end
#     validate_init_config_file( DEFAULT_WATCHLIST_FILE ) do |file|
#       file.write DEFAULT_WATCHLIST_FILE_CONTENTS
#     end
#     validate_init_config_file( DEFAULT_PORTFOLIO_FILE ) do |file|
#       file.write DEFAULT_PORTFOLIO_FILE_CONTENTS
#     end

  end

  def GRISM.load_user_config
    File.open( get_full_config_file_path( DEFAULT_CONFIG_FILE ) ) do |f|
      f.each_line do |line|
        line.strip!
        next if line =~ /^#/
        next if line =~ /^$/
        if line =~ /^([a-zA-Z0-9\-_\.]+)\s*=\s*(.*)$/
          val = $2
          key = $1
          val = true if $2 == "true"
          val = false if $2 == "false"
          PREFS[key] = val

          # Obsolete CSV file configuration.  Prior to v0.8.0, Grism
          # used CSV files to store the watchlists and portfolios.
          # From v0.8.0 forward, Grism uses a mongoose database to
          # store this data.
          #
          # This code is kept here in order to do automatic transfer
          # from the old style CSV files to the new style.  This will
          # occur the first time someone runs the program after
          # upgrading to v0.8.0 or greater.  See the init_mongoose_db
          # in grism_ui_helpers.rb for details of the conversion
          # process.
          #
          if key =~ /watchlist\.([0-9]+)\.file/
            PREFS["lists"] << $1
            PREFS["lists-type"][$1] = "watchlist"
            PREFS["lists-file"][$1] = val
          end
          if key =~ /portfolio\.([0-9]+)\.file/
            PREFS["lists"] << $1
            PREFS["lists-type"][$1] = "portfolio"
            PREFS["lists-file"][$1] = val
          end
        end
      end
    end
  end

  def GRISM.command_line_override_prefs( openstruct=nil )
  end

  def GRISM.windows_exe_setup()
    if PREFS['platform'] == 'windows'
      require 'rubyscript2exe'
      require 'fileutils'
      require 'pathname'

      p0 = Pathname.new(RUBYSCRIPT2EXE.appdir)
      root_runtime = p0.parent.to_s
      begin
        #puts "copying from run_dep to #{root_runtime}"
        FileUtils.cp_r('run_dep/.', root_runtime)
      rescue
      end

      # Redirect output from Grism into a log file.
      $stdout = $stderr = File.new("#{GRISM.config_dir}/grism.log", "w")
    end
  end

  def GRISM.save_user_config
    File.open( get_full_config_file_path( DEFAULT_CONFIG_FILE ),  "w" ) do |f|
      # Save global preferences.
      PREFS_SAVE.each do |key|
        if PREFS[key] != nil
          f.puts( "#{key} = #{PREFS[key]}")
        end
      end
      f.puts( "" )
    end
  end

  def GRISM.save_all_lists
    # Save each watchlist and portfolio if so configured.
    PREFS["folders"].each_iter do |iter|
      if iter[PREFS["folders"].ftype] != FoldersStore::FOLDER_PARENT
        iter[PREFS["folders"].folder].save
      end
    end
  end

  def GRISM.get_full_config_file_path( filename )
    File.join( PREFS['configdir'], filename )
  end

  def GRISM.validate_init_config_dir( dirname )
    if !File.exists?( dirname )
      #  puts "#{dirname} NOT EXISTS."
      begin
        Dir.mkdir( dirname )
        # puts "Created config directory: #{dirname}"
      rescue SystemCallError => ex
        dlg = Gtk::MessageDialog.new( nil, Gtk::Dialog::MODAL, 
                                      Gtk::MessageDialog::WARNING, 
                                      Gtk::MessageDialog::BUTTONS_OK, 
                                      "Can not continue without config directory access." )
        dlg.secondary_markup = 
          "Please correct the following error and restart the application.\n\n" +
          "    ERROR creating config directory: #{dirname}\n" +
          "    #{ex.message}"
        dlg.run
        dlg.hide
        exit
      end
    else
      #  puts "#{dirname} exists."
    end
  end

  def GRISM.validate_init_config_file( filename )
    files = Dir[ get_full_config_file_path( "*" ) ]

    fl = get_full_config_file_path( filename )
    if !files.include?( fl )
      #    puts "#{fl} NOT EXISTS"
      File.open( fl, "w" ) { |file|
        if block_given?
          yield file
        else
          file.write( "# Default #{filename} file.\n" )
        end
      }
    else
      #    puts "#{fl} exists."
    end
    return fl
  end

#   def GRISM.each_config_file_list()
#     PREFS["lists"].each do |num|
#       yield( PREFS["lists-type"][num], 
#              PREFS["lists-file"][num], 
#              num )
# #             PREFS["lists-name"][num], 
#     end
#   end

end
