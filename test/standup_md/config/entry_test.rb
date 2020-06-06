require_relative '../../test_helper'
require_relative '../../../lib/standup_md'

class TestEntryConfig < TestHelper
  def setup
    super
    StandupMD.config.entry.reset_values
  end

  def test_reset_values
    StandupMD.config.entry.current = ['test']
    assert_equal(['test'], StandupMD.config.entry.current)
    assert(StandupMD.config.entry.reset_values)
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)
  end

  def test_current
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)
    assert_nothing_raised { StandupMD.config.entry.current= ['An array'] }
    assert_equal(["An array"], StandupMD.config.entry.current)
  end

  def test_impediments
    assert_equal(["None"], StandupMD.config.entry.impediments)
    new_impediments = ['Impediment 1']
    assert_nothing_raised { StandupMD.config.entry.impediments = new_impediments }
    assert_equal(new_impediments, StandupMD.config.entry.impediments)
  end

  def test_notes
    assert_equal([], StandupMD.config.entry.notes)
    new_notes = ['Note 1']
    assert_nothing_raised { StandupMD.config.entry.notes = new_notes }
    assert_equal(new_notes, StandupMD.config.entry.notes)
  end
end
