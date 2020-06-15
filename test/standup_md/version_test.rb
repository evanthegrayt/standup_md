# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/standup_md'

class TestVersion < TestHelper

  def test_VERSION
    assert_match(/\d+\.\d+.\d+/, StandupMD::VERSION)
  end
end
