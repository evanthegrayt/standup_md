require_relative '../../test_helper'
require_relative '../../../lib/standup_md'

class TestFileConfig < TestHelper
  def setup
    super
    StandupMD.config.file.reset_values
  end

  def test_reset_values
    StandupMD.config.file.header_depth = 3
    assert_equal(3, StandupMD.config.file.header_depth)
    assert(StandupMD.config.file.reset_values)
    assert_equal(1, StandupMD.config.file.header_depth)
  end

  def test_bullet_character
    assert_equal('-', StandupMD.config.file.bullet_character)
    assert_nothing_raised { StandupMD.config.file.bullet_character = '*' }
    assert_equal('*', StandupMD.config.file.bullet_character)
    assert_raise { StandupMD.config.file.bullet_character = '>' }
  end

  def test_header_depth
    assert_equal(1, StandupMD.config.file.header_depth)
    assert_raise { StandupMD.config.file.header_depth = 6 }
    assert_raise { StandupMD.config.file.header_depth = 0 }
    assert_nothing_raised { StandupMD.config.file.header_depth = 3 }
    assert_equal(3, StandupMD.config.file.header_depth)
    assert_equal(4, StandupMD.config.file.sub_header_depth)
  end

  def test_sub_header_depth
    assert_nothing_raised { StandupMD.config.file.sub_header_depth = 2 }
    assert_equal(2, StandupMD.config.file.sub_header_depth)
    assert_raise { StandupMD.config.file.sub_header_depth = 1 }
    assert_raise { StandupMD.config.file.sub_header_depth = 7 }
    assert_nothing_raised { StandupMD.config.file.sub_header_depth = 6 }
    assert_equal(6, StandupMD.config.file.sub_header_depth)
    assert_nothing_raised { StandupMD.config.file.header_depth = 3 }
    assert_equal(3, StandupMD.config.file.header_depth)
    assert_nothing_raised { StandupMD.config.file.sub_header_depth = 3 }
    assert_equal(3, StandupMD.config.file.sub_header_depth)
    assert_equal(2, StandupMD.config.file.header_depth)
  end

  def test_name_format
    assert_equal('%Y_%m.md', StandupMD.config.file.name_format)
    assert_nothing_raised { StandupMD.config.file.name_format = '%y_%m.markdown' }
    assert_equal('%y_%m.markdown', StandupMD.config.file.name_format)
  end

  def test_current_header
    assert_equal('Current', StandupMD.config.file.current_header)
    assert_nothing_raised { StandupMD.config.file.current_header = 'Today' }
    assert_equal('Today', StandupMD.config.file.current_header)
  end

  def test_previous_header
    assert_equal('Previous', StandupMD.config.file.previous_header)
    assert_nothing_raised { StandupMD.config.file.previous_header = 'Yesterday' }
    assert_equal('Yesterday', StandupMD.config.file.previous_header)
  end

  def test_impediments_header
    assert_equal('Impediments', StandupMD.config.file.impediments_header)
    assert_nothing_raised { StandupMD.config.file.impediments_header = 'Hold Ups' }
    assert_equal('Hold Ups', StandupMD.config.file.impediments_header)
  end

  def test_notes_header
    assert_equal('Notes', StandupMD.config.file.notes_header)
    assert_nothing_raised { StandupMD.config.file.notes_header = 'Remember' }
    assert_equal('Remember', StandupMD.config.file.notes_header)
  end
end
