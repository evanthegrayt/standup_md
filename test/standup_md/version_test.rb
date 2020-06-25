# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/standup_md'

class TestVersion < TestHelper
  def test_to_s
    assert_match(/\d+\.\d+.\d+/, StandupMD::Version.to_s)
  end

  def test_major
    assert_instance_of(Integer, StandupMD::Version::MAJOR)
  end

  def test_minor
    assert_instance_of(Integer, StandupMD::Version::MINOR)
  end

  def test_patch
    assert_instance_of(Integer, StandupMD::Version::PATCH)
  end
end
