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
module Charting

  DAY = 1
  WEEK = 2
  WEEK2 = 3
  MONTH = 4
  MONTH2 = 5
  QUARTER = 6
  QUARTER2 = 7
  YEAR = 10
  DIY = 365
  DIM = 31
  DIW = 7

  XLABEL_MONTHS = %w( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )

  YQUANTITY_SMALL = [5,4,3]
  YQUANTITY_STANDARD = [8,7,6,5,4]

  YVALUE_SELF = 1
  YVALUE_THOUSANDS = 1000
  YVALUE_MILLIONS = 1000000

  #
  # Parse the string date (format: YYYY-MM-DD) into a 3 element array
  # ([YYYY,MM,DD]). This is used instead of the Date.parse method in
  # the x_date method below in order to optimize the GraphData
  # initialization.
  #
  def Charting.date_to_ary( date )
    [ date[0,4].to_i, date[5,2].to_i, date[8,2].to_i ]
  end

  def Charting.y_bounds( min, max, step_quantity=YQUANTITY_STANDARD )
    ret = nil
    dif = max - min
    if dif <= 10
      [1.0, 0.5, 0.2].each do |epsilon|
        ret = y_step( min, max, epsilon, step_quantity )
        break if ret
      end
    else
      epsilon = 5
      epsilon = 1 if dif > 10 and dif < 40
      epsilon = 25 if dif > 100
      epsilon = 100 if dif > 1000
      epsilon = 1000 if dif > 10000
      epsilon = 10000 if dif > 100000
      epsilon = 100000 if dif > 1000000
      epsilon = 1000000 if dif > 10000000

      ret = y_step( min, max, epsilon, step_quantity )
      ctr = epsilon
      newmin = min
      while !ret
        # First bump up the max.
        newmax = (max+ctr) - ((max + ctr) % epsilon)
        ret = y_step( newmin, newmax, epsilon, step_quantity )
        break if ret

        # If that didn't work, bump down the min.
        newmin = (min - ctr) + (epsilon - (min % epsilon))
        #newmin = (min - ctr) - ((min - ctr) % epsilon)
        newmin = 0 if newmin < 0
        ret = y_step( newmin, newmax, epsilon, step_quantity )
        break if ret

        ctr += epsilon
      end
    end
    ret
  end
  def Charting.y_step( min, max, epsilon, step_quantity )
    #puts "find_y_step( #{min}, #{max}, #{epsilon} )"
#    [8,7,6,5,4].each do |step|
    step_quantity.each do |step|
      ydelta = (max - min)/step.to_f
      # Use this (abs(x-y) < epsilon) method rather than ==.
      #
      # if ((ydelta - ((max - min)/step)) - epsilon).abs < 0.00000001
      #
      # Comparing floating points with == is asking for trouble
      # because of the rounding error inherant in binary floatin point
      # number representation.
      #
      if (ydelta % epsilon).abs < 0.00000001
        return [min,max,step,ydelta]
      end
    end
    nil
  end
  def Charting.y_label_type( step )
    if step < 10000
      [YVALUE_SELF, nil]
    elsif step < 1000000
      [YVALUE_THOUSANDS, "Thousands"]
    else
      [YVALUE_MILLIONS, "Millions"]
    end
  end
  def Charting.y_label( type, val )
    case type
    when YVALUE_SELF
      val
    when YVALUE_THOUSANDS
      val/1000
    when YVALUE_MILLIONS
      val/1000000
    end
  end
  
  def Charting.x_label( date, xspacer )
    d = Date.parse( date )
    #puts "get_xnum( #{date}, #{xspacer} )"
    case xspacer
    when DAY
      return "#{d.mday}-#{XLABEL_MONTHS[d.mon-1]}"
    when WEEK
      return "#{d.mday}-#{XLABEL_MONTHS[d.mon-1]}"
    when WEEK2
      return "#{d.mday}-#{XLABEL_MONTHS[d.mon-1]}"
    when MONTH
      return "#{XLABEL_MONTHS[d.mon-1]}-#{d.year.to_s[2,3]}"
    when MONTH2
      return "#{XLABEL_MONTHS[d.mon-1]}-#{d.year.to_s[2,3]}"
    when QUARTER
      return "#{XLABEL_MONTHS[d.mon-1]}-#{d.year.to_s[2,3]}"
    when QUARTER2
      return "#{XLABEL_MONTHS[d.mon-1]}-#{d.year.to_s[2,3]}"
    else #YEAR
      return "#{d.year}"
    end
  end

  def Charting.x_type( days, sdd, edd )
    spacer = 0

    case days
    when 0..8
      spacer = DAY
    when 9..40
      spacer = WEEK
    when 41..80
      spacer = WEEK2
    when 81..160
      spacer = MONTH
    end

    return [days,spacer] if spacer != 0

    days = edd - sdd
    case days
    when 0..DIY
      spacer = MONTH2
    when (DIY+1)..(DIY*2)
      spacer = QUARTER
    when ((DIY*2)+1)..(DIY*4)
      spacer = QUARTER2
    else
      spacer = YEAR + (days.to_i/DIY/4)
    end

    return [days,spacer]
  end

  def Charting.x_date( date, dayofweek, datelast, xspacer, ctr, tmp )
    return [date,ctr,tmp,Charting.date_to_ary(date)] if xspacer == DAY

    retdate = nil
    d = Charting.date_to_ary( date ) << dayofweek

    case xspacer
    when WEEK
      retdate = date if dayofweek <= datelast[3]
    when WEEK2
      if dayofweek <= datelast[3]
        if ctr == 1
          retdate = date
          ctr = 0
        else
          ctr += 1
        end
      end
    when MONTH
      if d[1] != tmp
        retdate = date
        tmp = d[1]
      end
    when MONTH2
      if d[1] != tmp
        tmp = d[1]
        if ctr == 1
          retdate = date
          ctr = 0
        else
          ctr += 1
        end
      end
    when QUARTER
      if d[1] == 1 or d[1] == 4 or d[1] == 7 or d[1] == 10
        if d[1] != tmp
          retdate = date
          tmp = d[1]
        end
      end
    when QUARTER2
      if d[1] == 1 or d[1] == 4 or d[1] == 7 or d[1] == 10
        if d[1] != tmp
          tmp = d[1]
          if ctr == 1
            retdate = date
            ctr = 0
          else
            ctr += 1
          end
        end
      end
    else # YEAR
      year = xspacer - YEAR
      if d[0] != tmp
        tmp = d[0]
        if ctr == year
          retdate = date
          ctr = 1
        else
          ctr += 1
        end
      end
    end

    [retdate,ctr,tmp,d]
  end

end
