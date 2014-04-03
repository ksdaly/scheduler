require 'test_helper'

class HiveSchedulerTest < ActiveSupport::TestCase

  # set Time.now to a value that does not change for any of the tests
  before do
    Timecop.freeze(Time.local(2014,2,15,12,15,0))
  end

  after do
    Timecop.return
  end

  # tests do not work with weekdays as Date.parse is not affected by Timecop

  # tests for a single field
  # minute, hour, day of month, month of year

  # MINUTE

  test 'minute in future' do
    args = { minutes: '30', hours: '*', days: '*', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,15,12,30), next_run_at)
  end

  test 'minute in past: rollover to next hour' do
    args = { minutes: '0', hours: '*', days: '*', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,15,13,0), next_run_at)
  end

  test 'minute with multiple values' do
    args = { minutes: '0, 30, 45', hours: '*', days: '*', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,15,12,30), next_run_at)
  end

  # HOUR

  test 'hour in future' do
    args = { minutes: '*', hours: '15', days: '*', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,15,15,0), next_run_at)
  end

  test 'hour with multiple values' do
    args = { minutes: '*', hours: '9, 15, 18', days: '*', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,15,15,0), next_run_at)
  end

  # DAY

  test 'day in future' do
    args = { minutes: '*', hours: '*', days: '20', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,20,0,0), next_run_at)
  end

  test 'day in past: rollover to next month' do
    args = { minutes: '*', hours: '*', days: '10', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,10,0,0), next_run_at)
  end

  test 'day with multiple values' do
    args = { minutes: '*', hours: '*', days: '10, 20, 25', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,20,0,0), next_run_at)
  end

  test 'day outside of range: rollover to next valid month' do
    args = { minutes: '*', hours: '*', days: '31', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,31,0,0), next_run_at)
  end

  # MONTH

  test 'month in future' do
    args = { minutes: '*', hours: '*', days: '*', months: '6', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,6,1,0,0), next_run_at)
  end

  test 'month in past: rollover to next year' do
    args = { minutes: '*', hours: '*', days: '*', months: '1', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2015,1,1,0,0), next_run_at)
  end

  test 'month with multiple values' do
    args = { minutes: '*', hours: '*', days: '*', months: '1, 6, 12', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,6,1,0,0), next_run_at)
  end

  # combination tests: 2 fields
  # MINUTE +

  test 'minute and hour' do
    args = { minutes: '30', hours: '16', days: '*', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,15,16,30), next_run_at)
  end

  test 'minute and day' do
    args = { minutes: '30', hours: '*', days: '20', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,20,0,30), next_run_at)
  end

  test 'minute and month' do
    args = { minutes: '30', hours: '*', days: '*', months: '3', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,1,0,30), next_run_at)
  end

  # HOUR +

  test 'hour and day' do
    args = { minutes: '*', hours: '15', days: '20', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,2,20,15,0), next_run_at)
  end

  test 'hour and month' do
    args = { minutes: '*', hours: '15', days: '*', months: '3', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,1,15,0), next_run_at)
  end

  # DAY +

  test 'day and month' do
    args = { minutes: '*', hours: '*', days: '20', months: '3', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,20,0,0), next_run_at)
  end

  # combination tests: 3 fields
  # MINUTE & HOUR +

  test 'minute and hour and day' do
    args = { minutes: '30', hours: '16', days: '1', months: '*', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,1,16,30), next_run_at)
  end

  test 'minute and hour and month' do
    args = { minutes: '30', hours: '16', days: '*', months: '3', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,1,16,30), next_run_at)
  end

  # MINUTE & DAY +

  test 'minute and day and month' do
    args = { minutes: '30', hours: '*', days: '1', months: '3', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,1,0,30), next_run_at)
  end

  # combination tests: 4 fields

  test 'minute and hour and day and month' do
    args = { minutes: '30', hours: '15', days: '1', months: '3', weekdays: '*' }
    next_run_at = HiveScheduler::Scheduler.new(args).next_run_at
    assert_equal(DateTime.new(2014,3,1,15,30), next_run_at)
  end

  # impossibel dates

  test 'date does not exist' do
    args = { minutes: '*', hours: '*', days: '30', months: '2', weekdays: '*' }
    assert_raises(ArgumentError) { HiveScheduler::Scheduler.new(args).next_run_at }
  end
end
