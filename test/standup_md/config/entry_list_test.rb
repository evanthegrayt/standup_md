# frozen_string_literal: true

require_relative "../../test_helper"

class TestEntryListConfig < Test::Unit::TestCase
  def test_initialize
    assert_nothing_raised { StandupMD::Config::EntryList.new }
  end

  def test_reset
    assert_instance_of(Hash, StandupMD.config.entry_list.reset)
    assert_equal({}, StandupMD.config.entry_list.reset)
  end
end
