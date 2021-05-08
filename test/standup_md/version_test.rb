# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/standup_md'

class TestVersion < TestHelper
  def test_to_a
    assert_equal(
      [
        StandupMD::Version::MAJOR,
        StandupMD::Version::MINOR,
        StandupMD::Version::PATCH
      ],
      StandupMD::Version.to_a
    )
  end

  def test_to_h
    assert_equal(
      {
        major: StandupMD::Version::MAJOR,
        minor: StandupMD::Version::MINOR,
        patch: StandupMD::Version::PATCH
      },
      StandupMD::Version.to_h
    )
  end

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
