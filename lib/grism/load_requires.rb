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
# Add the directory containing the external project files bundled with
# Grism to the require load path.  This is so that we can say:
#
# require 'external_xyz'
#
# And in the external project files, they can say:
#
# require 'xyz/abc123'
#
$LOAD_PATH << File.expand_path( File.dirname( __FILE__  ) + '/extern' )
#puts $LOAD_PATH

# Require the external projects bundled with Grism.
require 'yahoofinance'
require 'kirbybase'
require 'mongoose'

# Require other dependent projects not bundled with Grism.
require 'libglade2'
require 'thread'
require 'date'
require 'base64'

begin
  require 'faster_csv'
rescue LoadError
  require 'csv'
end

# Require Grism files.
require 'grism/config'
require 'grism/version'
require 'grism/grism_constants'
require 'grism/generic_store'
require 'grism/grism_signal'
require 'grism/GrismListStore'
require 'grism/grism_treeviews'
require 'grism/chart/chart'
require 'grism/grism_ui_helpers'

require 'grism/InfoBar'
require 'grism/PreferencesIconBar'

require 'grism/GenericDialog'
require 'grism/PreferencesDialog'
require 'grism/AboutDialog'
require 'grism/ExportChartDialog'
require 'grism/WatchListDialog'
require 'grism/PortfolioDialog'
require 'grism/PortfolioHistoryDialog'
require 'grism/WPListPropertiesDialog'
require 'grism/SplitDialog'
require 'grism/RenameDialog'

require 'grism/GrismFolderTypeWidget'
require 'grism/ParentWidget'
require 'grism/FoldersStore'
require 'grism/Folders'
require 'grism/MoveCopyDialog'

require 'grism/mongoose_db'
require 'grism/ChartWidget'
require 'grism/WPListWidget'
require 'grism/WatchListStore'
require 'grism/WatchListWidget'
require 'grism/PortfolioStore'
require 'grism/PortfolioHistoryStore'
require 'grism/PortfolioWidget'
require 'grism/CashDialog'
