# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
require File.expand_path 'lib/app/utils/search_validation.rb'
class AssertionsTest < MiniTest::Test
  include Inferno::SearchValidationUtil

  def setup
    # Create an instance of an anonymous class to wrap Inferno's assertions which collide/conflct with the tests methods
    @inferno_asserter = Class.new do
      include Inferno::Assertions
    end.new
  end

  def error_string(search, target, truth)
    "Search Value: #{search}, Target Value: #{target}, Expectation: #{truth}"
  end

  def search_contains_target
    {
      eq: true,
      ne: false,
      gt: false,
      lt: false,
      ge: true,
      le: true,
      sa: false,
      eb: false,
      ap: true
    }
  end

  def search_below_target
    {
      eq: false,
      ne: true,
      gt: true,
      lt: false,
      ge: true,
      le: false,
      sa: true,
      eb: false,
      ap: false
    }
  end

  def search_above_target
    {
      eq: false,
      ne: true,
      gt: false,
      lt: true,
      ge: false,
      le: true,
      sa: false,
      eb: true,
      ap: false
    }
  end

  def target_contains_search
    {
      eq: false,
      ne: true,
      gt: true,
      lt: true,
      ge: true,
      le: true,
      sa: false,
      eb: false,
      ap: true
    }
  end

  def search_overlaps_above_target
    {
      eq: false,
      ne: true,
      gt: false,
      lt: true,
      ge: false,
      le: true,
      sa: false,
      eb: false,
      ap: true
    }
  end

  def search_overlaps_below_target
    {
      eq: false,
      ne: true,
      gt: true,
      lt: false,
      ge: true,
      le: false,
      sa: false,
      eb: false,
      ap: true
    }
  end

  def assert_date_search_expectations(search_expectations)
    search_expectations[:targets].each do |target|
      target[:comparators].each do |comparator, truth_value|
        search_val = comparator.to_s + search_expectations[:search]
        assert validate_date_search(search_val, target[:value]) == truth_value, error_string(search_val, target[:value], truth_value)
      end
    end
  end

  def assert_period_search_expectations(search_expectations)
    search_expectations[:targets].each do |target|
      target[:comparators].each do |comparator, truth_value|
        search_val = comparator.to_s + search_expectations[:search]
        assert validate_period_search(search_val, target[:value]) == truth_value, error_string(search_val, target[:value], truth_value)
      end
    end
  end

  def test_datetime_year_year
    search_expectations = {
      search: '2001',
      targets: [
        {
          value: '2001',
          comparators: search_contains_target
        },
        {
          value: '2002',
          comparators: search_below_target
        },
        {
          value: '2000',
          comparators: search_above_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_year_month
    search_expectations = {
      search: '2001',
      targets: [
        {
          value: '2001-12',
          comparators: search_contains_target
        },
        {
          value: '2001-01',
          comparators: search_contains_target
        },
        {
          value: '2001-12',
          comparators: search_contains_target
        },
        {
          value: '2002-01',
          comparators: search_below_target
        },
        {
          value: '2000-12',
          comparators: search_above_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_year_day
    search_expectations = {
      search: '2001',
      targets: [
        {
          value: '2001-12-31',
          comparators: search_contains_target
        },
        {
          value: '2001-01-01',
          comparators: search_contains_target
        },
        {
          value: '2001-12-31',
          comparators: search_contains_target
        },
        {
          value: '2002-01-01',
          comparators: search_below_target
        },
        {
          value: '2000-12-31',
          comparators: search_above_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_month_year
    search_expectations = {
      search: '2001-04',
      targets: [
        {
          value: '2001',
          comparators: target_contains_search
        },
        {
          value: '2002',
          comparators: search_below_target
        },
        {
          value: '2000',
          comparators: search_above_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_month_month
    search_expectations = {
      search: '2001-04',
      targets: [
        {
          value: '2001-04',
          comparators: search_contains_target
        },
        {
          value: '2001-01',
          comparators: search_above_target
        },
        {
          value: '2001-12',
          comparators: search_below_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_month_day
    search_expectations = {
      search: '2001-04',
      targets: [
        {
          value: '2001-04-01',
          comparators: search_contains_target
        },
        {
          value: '2001-04-30',
          comparators: search_contains_target
        },
        {
          value: '2001-03-31',
          comparators: search_above_target
        },
        {
          value: '2001-05-01',
          comparators: search_below_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_day_year
    search_expectations = {
      search: '2001-04-03',
      targets: [
        {
          value: '2001',
          comparators: target_contains_search
        },
        {
          value: '2000',
          comparators: search_above_target
        },
        {
          value: '2002',
          comparators: search_below_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_day_month
    search_expectations = {
      search: '2001-04-03',
      targets: [
        {
          value: '2001-04',
          comparators: target_contains_search
        },
        {
          value: '2001-03',
          comparators: search_above_target
        },
        {
          value: '2001-05',
          comparators: search_below_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_day_day
    search_expectations = {
      search: '2001-04-03',
      targets: [
        {
          value: '2001-04-03',
          comparators: search_contains_target
        },
        {
          value: '2001-04-02',
          comparators: search_above_target
        },
        {
          value: '2001-04-04',
          comparators: search_below_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_datetime_time_time
    search_expectations = {
      search: DateTime.new(2001, 4, 3, 4, 5, 6).xmlschema,
      targets: [
        {
          value: DateTime.new(2001, 4, 3, 4, 5, 6).xmlschema,
          comparators: search_contains_target
        },
        {
          value: DateTime.new(2001, 4, 2, 4, 5, 6).xmlschema,
          comparators: search_above_target
        },
        {
          value: DateTime.new(2001, 4, 6, 4, 5, 6).xmlschema,
          comparators: search_below_target
        }
      ]
    }
    assert_date_search_expectations(search_expectations)
  end

  def test_period_search_year
    search_expectations = {
      search: '2001',
      targets: [
        {
          value: OpenStruct.new(start: '2000-04-12', end: '2000-12-31'),
          comparators: search_above_target
        },
        {
          value: OpenStruct.new(start: '2000-04', end: '2001-04'),
          comparators: search_overlaps_above_target
        },
        {
          value: OpenStruct.new(start: '2001', end: '2001'),
          comparators: search_contains_target
        },
        {
          value: OpenStruct.new(start: '2001-01-01', end: '2001-12'),
          comparators: search_contains_target
        },
        {
          value: OpenStruct.new(start: '2001-01-04', end: '2002-04'),
          comparators: search_overlaps_below_target
        },
        {
          value: OpenStruct.new(start: '2002-04-12', end: '2002-08-09'),
          comparators: search_below_target
        },
        {
          value: OpenStruct.new(start: '2000-04-12', end: '2002-03-09'),
          comparators: target_contains_search
        },
        {
          value: OpenStruct.new(start: nil, end: '2000-03-09'),
          comparators: search_above_target
        },
        {
          value: OpenStruct.new(start: nil, end: '2001-03-09'),
          comparators: search_overlaps_above_target
        },
        {
          value: OpenStruct.new(start: nil, end: '2002-03-09'),
          comparators: target_contains_search
        },
        {
          value: OpenStruct.new(start: '2002-03-09', end: nil),
          comparators: search_below_target
        },
        {
          value: OpenStruct.new(start: '2001-03-09', end: nil),
          comparators: search_overlaps_below_target
        },
        {
          value: OpenStruct.new(start: '2000-03-09', end: nil),
          comparators: target_contains_search
        }
      ]
    }
    assert_period_search_expectations(search_expectations)
  end

  def test_period_search_time
    search_expectations = {
      search: DateTime.new(2001, 4, 3, 4, 5, 6).xmlschema,
      targets: [
        {
          value: OpenStruct.new(start: DateTime.new(2001, 4, 3, 4, 5, 6).xmlschema, end: DateTime.new(2001, 4, 3, 4, 5, 6).xmlschema),
          comparators: search_contains_target
        },
        {
          value: OpenStruct.new(start: DateTime.new(2001, 4, 4, 4, 5, 6).xmlschema, end: DateTime.new(2001, 4, 4, 5, 5, 6).xmlschema),
          comparators: search_below_target
        },
        {
          value: OpenStruct.new(start: DateTime.new(2001, 4, 2, 4, 5, 6).xmlschema, end: DateTime.new(2001, 4, 2, 5, 5, 6).xmlschema),
          comparators: search_above_target
        },
        {
          value: OpenStruct.new(start: DateTime.new(2001, 4, 1, 4, 5, 6).xmlschema, end: DateTime.new(2001, 4, 6, 5, 5, 6).xmlschema),
          comparators: target_contains_search
        }
      ]
    }
    assert_period_search_expectations(search_expectations)
  end
end
