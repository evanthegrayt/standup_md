require_relative '../test_helper'
require_relative '../../lib/standup_md'

class TestFile < TestHelper
  def setup
    super
    StandupMD.config.file.reset
    StandupMD.config.file.directory = workdir
    @previous_month_test_file = Date.today.prev_month.strftime('%Y_%m.md')
    create_standup_file(test_file_name)
    @file = StandupMD::File.new(::File.basename(test_file_name))
  end

  def test_initialize
    assert_equal(
      test_file_name, StandupMD::File.new(::File.basename(test_file_name)).name
    )
    assert_equal(
      test_file_name,
      StandupMD::File.new(::File.basename(test_file_name)).name
    )
  end

  def test_new?
    file = StandupMD::File.new(
      Date.today.strftime(StandupMD.config.file.name_format)
    )
    refute(file.new?)

    file = StandupMD::File.new(
      Date.today.next_month.strftime(StandupMD.config.file.name_format)
    )
    assert(file.new?)
  end

  def test_find
    file = StandupMD::File.find(File.basename(test_file_name))
    assert_instance_of(StandupMD::File, file)
    assert_equal(test_file_name, file.name)
    StandupMD.config.file.create = false
    assert_raise { StandupMD::File.find('noexist') }
    StandupMD.config.file.create = true
    assert_nothing_raised { StandupMD::File.find('noexist') }
  end

  def test_find_by_date
    assert_raise { StandupMD::File.find_by_date(fixtures['today_date']) }
    file = StandupMD::File.find_by_date(Date.today)
    assert_instance_of(StandupMD::File, file)
    assert_equal(test_file_name, file.name)
    StandupMD.config.file.create = false
    assert_raise {StandupMD::File.find_by_date(Date.today.prev_year) }
    StandupMD.config.file.create = true
    assert_nothing_raised { StandupMD::File.find_by_date(Date.today.prev_year) }
  end

  def test_name
    assert_equal(test_file_name, @file.name)
  end

  def test_exist?
    assert(@file.exist?)
    FileUtils.rm(@file.name)
    refute(@file.exist?)
  end

  def test_load
    refute(@file.loaded?)
    assert_nothing_raised { @file.load }
    assert(@file.loaded?)
    file = @file.load
    assert_instance_of(StandupMD::File, file)
    entry_list = file.entries
    assert_instance_of(StandupMD::EntryList, entry_list)
    assert_equal(2, entry_list.size)
    StandupMD.config.file.current_header = 'Today'
    assert_raise { @file.load }
  end

  def test_write
    @file.load
    assert(@file.write)
    refute(::File.zero?(@file.name))
    assert_nothing_raised { @file.load }
  end
end
