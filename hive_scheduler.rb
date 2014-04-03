module HiveScheduler

  class Scheduler

    # Array of integers representing all time unit values
    # that the schedule needs to run on.
    # Original input passed to HiveScheduler::Scheduler can be accessed
    # as an intance variable
    # Example usage:
    # weekdays   #=> [0,1,2,3,4,5,6]
    # @weekdays  #=> '*'
    attr_writer :minutes, :hours, :weekdays, :days, :months

    # The datetime used for comparison to determine the next scheduled DateTime.
    attr_accessor :base_time

    # Delegates Time instance methods #year, #month, #day, #wday, #min to base_time
    # Can be accessed using a prefix 'base'
    # Example usage:
    # base_year #=> same as base_time.year
    delegate :year, :month, :day, :wday, :hour, :min, to: :base_time, allow_nil: true, prefix: :base

    # Takes an argument Hash consisting of five time unit variables with values
    # as comma separated strings:
    # minutes   #=> 0..59
    # hours     #=> 0..23
    # days      #=> 1..31
    # months    #=> 1..12
    # weekdays  #=> 0..6 with 0 == Sunday
    # Each of these variables can also be a wildcard as an asterisk('*') meaning all
    # valid values.
    # base_time attribute is a DateTime for comparison to determine next DateTime
    # to be scheduled. Default is DateTime.now.
    # Example usage:
    # { minutes: '0,30', hours: '*', days: '1', months: '*', weekdays: '*' }
    def initialize(attributes = {})
      attributes.each do |attribute,value|
        value ||= '*'
        self.send("#{attribute}=", value)
      end

      @base_time ||= DateTime.now
    end

    def minutes
      expand_cronspec(@minutes, 59)
    end

    def hours
      expand_cronspec(@hours, 24)
    end

    def weekdays
      expand_cronspec(@weekdays, 6, 0)
    end

    def days
      expand_cronspec(@days, 31, 1)
    end

    def months
      expand_cronspec(@months, 12, 1)
    end

    def now
      Time.now
    end

    # Takes the given cronspec argument as a string in one of these formats:
    # wildcrad: '*'
    # comma separated string: '0, 30'
    # and converts it into an (expanded) sorted array of integers representing all
    # time unit values that the schedule needs to run on.
    # Arguments 'max' and 'min' are needed to determine the expansion of wildcard
    def expand_cronspec(cronspec, max, min = 0)
      expanded_cronspec = []
      if cronspec == '*'
        min.step(max, 1) { |value| expanded_cronspec << value }
      else
        expanded_cronspec = cronspec.delete(' ').split(',').map { |n| n.to_i }.sort
      end
      expanded_cronspec
    end

    # Returns true if schedule includes same day, month and weekday as for base_time.
    def execute_this_date?
      months.include?(base_month) && days.include?(base_day) && weekdays.include?(base_wday)
    end

    # Returns true if next scheduled DateTime is within the same date and hour as base_time.
    def execute_this_hour?
      execute_this_date? && base_month == now.month && base_day == now.day && base_wday == now.wday && hours.include?(base_hour) && base_min < minutes.max
    end

    # Returns true if next scheduled DateTime is within the same date but at a different hour
    # as base_time
    def execute_today?
      execute_this_date? && base_hour < hours.max
    end

    # Returns true if schedule includes every day and every month.
    def execute_all_days_and_months?
      @days == '*' && @months == '*'
    end

    # Returns true if next scheduled month is same as for base_time.
    def execute_this_month?
      months.include?(base_month) && base_day < days.max && !day_out_of_range?
    end

    # Returns true if next scheduled year is same as for base_time.
    def execute_this_year?
      months.include?(next_time_value(months, base_month))
    end

    # Ensures that values in days that exceed the number of days of the current month
    # are disregarded.
    def day_out_of_range?
      next_time_value(days, base_day) > Time.days_in_month(base_month)
    end

    # Returns next largest possible time unit value.
    # Only used when it is possible without rolling over.
    def next_time_value(expanded_cronspec, time_unit)
      expanded_cronspec.bsearch { |x| x > time_unit }
    end

    # Returns adjustment for next week depending on wether weekday falls within the
    # current week or has to be adjusted for next week.
    def week_adjustment(next_wday)
      next_wday <= base_wday ? 7 : 0
    end

    # Returns next possible DateTime that schedule needs to run on.
    # The 'next_' value is determined comparing time unit values to base_time.
    #
    # If there is a smaller time unit than that being evaluated,
    # evaluation is first done in the context of time units that are  smaller or equal, e.g.,
    # within the same hour and day for day, and when true, returns the value of base_time.
    #
    # Next it is evaluated if the time unit is within the next larger time unit, e.g.,
    # within same month for day, and when true, returns next value in the time units array that
    # is larger than base_time.
    #
    # An excepton is made and takes precedence for when execute_all_days_and_months?
    # returns true.
    # In this case date returned by next_weekday is used
    # to determie next_day, next_month and next_year taking into account weekdays.
    #
    # In all other cases the value rolls over to the next larger time unit and
    # returns the smallest value in the time units array, e.g., days.min.,
    # with the exception of next_year, where year is incremented by 1.
    #
    # The sequence of case statements is important and should be as follows:
    # execute_this_hour?, execute_today?, execute_all_days_and_months?, execute_this_month, execute_this_year?
    def next_run_at
      DateTime.new(next_year, next_month, next_day, next_hour, next_minute)
    end

    def next_minute
      execute_this_hour? ? next_time_value(minutes, base_min) : minutes.min
    end

    def next_hour
      case
      when execute_this_hour? then base_hour
      when execute_today? then next_time_value(hours, base_hour)
      else hours.min
      end
    end

    # Only used if execute_all_days_and_months? returns true.
    # Returns a date adjusted for weekdays that is used to determine
    # next_day, next_month, next_year. This is important if
    # schedule is restricted to certain weekdays.
    # If either months or days are specified, the weekdays will be disregarded.
    def next_weekday
      next_wday = base_wday < weekdays.max ? next_time_value(weekdays, base_wday) : weekdays.min
      Date.parse(Date::DAYNAMES[next_wday]) + week_adjustment(next_wday)
    end

    def next_day
      case
      when execute_this_hour? || execute_today? then base_day
      when execute_all_days_and_months? then next_weekday.day
      when execute_this_month? then next_time_value(days, base_day)
      else days.min
      end
    end

    def next_month
      case
      when execute_this_hour? || execute_today? then base_month
      when execute_all_days_and_months? then next_weekday.month
      when execute_this_month? then base_month
      when execute_this_year? then next_time_value(months, base_month)
      else months.min
      end
    end

    def next_year
      case
      when execute_this_hour? || execute_today? then base_year
      when execute_all_days_and_months? then next_weekday.year
      when execute_this_month? || execute_this_year? then base_year
      else base_year + 1
      end
    end
  end

  module Values

    # This module contains time unit names and ranges used by HiveScheduler
    # for input validation and within templates.

    MINUTES = 0..59
    HOURS = 0..23
    WEEKDAYS = 0..6
    DAYS = 1..31
    MONTHS = 1..12

    def scheduler_fields
      [:minutes, :hours, :weekdays, :days, :months]
    end
  end

  class HiveSchedulerRangeValidator < ActiveModel::EachValidator

    # Custom validator to validate individual attributes.
    # Example usage:
    # validates :minutes, hive_scheduler_range: true

    def validate_each(record, attribute, value)
      unless valid_numeric_values(attribute, value) || valid_wildcard(value)
        record.errors[attribute] << (options[:message] || "is not in correct format, only use values in range #{ HiveScheduler::Values.const_get(attribute.upcase) } OR a single wildcard (*)")
      end
    end

    # Returns true if attribute contains only comma separated numbers,
    # each number being within the correct range for the attribute.
    def valid_numeric_values(attribute, value)
      value.delete(' ').split(',').all? {|item| is_number?(item) && HiveScheduler::Values.const_get(attribute.upcase).include?(item.to_i)}
    end

    #Returns true if attribute contains a single asterisk('*')
    def valid_wildcard(value)
      value.include?('*') && value.length == 1
    end

    def is_number?(string)
      true if Float(string) rescue false
    end
  end
end
