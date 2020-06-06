require_relative '../../test_helper'
require_relative '../../../lib/standup_md'

class TestEntryListConfig < Test::Unit::TestCase
  def test_reset_values
    assert(StandupMD.config.entry_list.reset_values)
  end
end
