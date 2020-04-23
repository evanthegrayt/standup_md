require_relative '../lib/standup_md'
require_relative 'test_helper'

##
# The test suite for +StandupMD+.
class TestStandupMD < Test::Unit::TestCase
  include TestHelper

  ##
  # Set working directory, current month's file, and last month's file, which
  # will be created and destroyed for each test.
  def setup
    @workdir = File.join(__dir__, 'files')
    @current_test_file =
      File.join(@workdir, Date.today.strftime('%Y_%m.md'))
    @previous_month_test_file =
      File.join(@workdir, Date.today.prev_month.strftime('%Y_%m.md'))
  end

  ##
  # Destroy the working directory and its contents.
  def teardown
    FileUtils.rm_r(@workdir) if File.directory?(@workdir)
    FileUtils.rm(@current_test_file) if File.file?(@current_test_file)
  end

  ##
  # Make sure load accepts a hash of attributes, sets them, and returns an
  # instance of itself.
  def test_class_load
    assert_nothing_raised do
      StandupMD.load({directory: @workdir, bullet_character: '*'})
    end
    su = StandupMD.load({directory: @workdir, bullet_character: '*'})
    assert_equal(@workdir, su.directory)
    assert_instance_of(StandupMD, su)
  end

  ##
  # Attributes should be able to be set if you pass a block at instantiation.
  def test_setting_attributes_via_block
    assert_nothing_raised { StandupMD.new { |su| su.directory = @workdir } }
    assert_raise { StandupMD.new { |su| su.not_a_method = 'something'} }
    su = StandupMD.new do |s|
      s.directory = @workdir
      s.file_name_format = '%y_%m.markdown'
      s.bullet_character = '*'
    end
    assert_equal(@workdir, su.directory)
    assert_equal('%y_%m.markdown', su.file_name_format)
    assert_equal('*', su.bullet_character)
  end

  ##
  # +StandupMD::VERSION+ should consist of three integers separated by dots.
  def test_VERSION
    assert_match(/\d+\.\d+.\d+/, ::StandupMD::VERSION)
  end

  ##
  # The file name should equal file_name_format parsed by Date.strftime.
  # The default is Date.today.strftime('%Y_%m.md')
  def test_file
    su = standup(@workdir)
    assert_equal(@current_test_file, su.file)
    assert_nothing_raised { su.file_name_format = '%y_%m.markdown' }
    assert_nothing_raised { su.load }
    assert_equal(
      File.join(@workdir, Date.today.strftime('%y_%m.markdown')),
      su.file
    )
  end

  ##
  # When neither last month's file, nor this month's file exist, previous_file
  # should be an empty string.
  def test_previous_file_when_current_and_previous_month_do_not_exist
    su = standup(@workdir)
    assert_equal('', su.previous_file)
  end

  ##
  # When last month's file exists, but this month's doesn't or is empty,
  # previous_file should equal last menth's file.
  def test_previous_file_when_current_month_file_does_not_exist_but_previous_does
    FileUtils.mkdir_p(@workdir)
    FileUtils.touch(@previous_month_test_file)
    su = standup(@workdir)
    assert_equal(@previous_month_test_file, su.previous_file)
    FileUtils.touch(@current_test_file)
    assert_nothing_raised { su.load }
    su = standup(@workdir)
    assert_equal(@previous_month_test_file, su.previous_file)
  end

  ##
  # If there are previous entries for this month, previous file will be this
  # month's file.
  def test_previous_file_when_entry_exists_for_today
    FileUtils.mkdir_p(@workdir)
    FileUtils.touch(@current_test_file)
    su = standup(@workdir)
    assert_nothing_raised { su.write }
    assert_nothing_raised { su.load }
    assert_equal(@current_test_file, su.previous_file)
  end

  ##
  # +current_entry+ should be a hash. If +file+ already has an entry for today,
  # it will be read and used as +current_entry+. If there is no entry for
  # today, one should be generated from scaffolding.
  def test_current_entry
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(
      fixtures['current_entry_tasks'][Date.today.strftime('%Y-%m-%d')],
      su.current_entry
    )
  end

  def test_all_previous_entries
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(
      fixtures['previous_entry_tasks'],
      su.all_previous_entries
    )
  end

  def test_directory
    su = standup(@workdir)
    assert_equal(@workdir, su.directory)
    assert_nothing_raised { su.directory = File.join(@workdir, 'TEST') }
    assert_equal(File.join(@workdir, 'TEST'), su.directory)
    assert(File.directory?(su.directory))
  end

  def test_sub_header_order
    su = standup(@workdir)
    assert_equal(%w[previous current impediments notes], su.sub_header_order)
    assert_raise { su.sub_header_order = 'not array' }
    assert_raise { su.sub_header_order = %w[current impediments notes] }
    assert_raise { su.sub_header_order = %w[something, :previous, :current, :impediments, :notes] }
    assert_nothing_raised { su.sub_header_order = %w[current previous impediments notes] }
    assert_equal(%w[current previous impediments notes], su.sub_header_order)
    assert_nothing_raised { su.sub_header_order << 'Another task' }
    assert_equal(su.sub_header_order, %w[current previous impediments notes])
  end

  def test_current_entry_tasks
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], su.current_entry_tasks)
    assert_raise { su.current_entry_tasks = 'not array' }
    assert_nothing_raised { su.current_entry_tasks = ['An array'] }
    assert_equal(["An array"], su.current_entry_tasks)
    assert_nothing_raised { su.current_entry_tasks << 'Another task' }
    assert_includes(su.current_entry_tasks, 'Another task')
  end

  def test_impediments
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(["None"], su.impediments)
    assert_raise { su.impediments = ''}
    new_impediments = ['Impediment 1']
    assert_nothing_raised { su.impediments = new_impediments }
    assert_equal(new_impediments, su.impediments)
  end

  def test_notes
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal([], su.notes)
    assert_raise { su.notes = ''}
    new_notes = ['Note 1']
    assert_nothing_raised { su.notes = new_notes }
    assert_equal(new_notes, su.notes)
  end

  def test_bullet_character
    su = standup(@workdir)
    assert_equal('-', su.bullet_character)
    assert_nothing_raised { su.bullet_character = '*' }
    assert_equal('*', su.bullet_character)
    assert_raise { su.bullet_character = '>' }
  end

  def test_header_depth
    su = standup(@workdir, sub_header_depth: 4)
    assert_equal(1, su.header_depth)
    assert_raise { su.header_depth = 6 }
    assert_raise { su.header_depth = 0 }
    assert_raise { su.header_depth = 5 }
    assert_nothing_raised { su.header_depth = 3 }
    assert_equal(3, su.header_depth)
  end

  def test_sub_header_depth
    su = standup(@workdir)
    assert_equal(2, su.sub_header_depth)
    assert_raise { su.sub_header_depth = 1 }
    assert_raise { su.sub_header_depth = 7 }
    assert_nothing_raised { su.sub_header_depth = 6 }
    assert_equal(6, su.sub_header_depth)
  end

  def test_previous_entry_tasks
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(["Test task 2", "Test task 4"], su.previous_entry_tasks)
    assert_raise { su.previous_entry_tasks = 'not array' }
    assert_nothing_raised { su.previous_entry_tasks = ['An array'] }
    assert_equal(["An array"], su.previous_entry_tasks)
    assert_nothing_raised { su.previous_entry_tasks << 'Another task' }
    assert_includes(su.previous_entry_tasks, 'Another task')
  end

  def test_file_name_format
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal('%Y_%m.md', su.file_name_format)
    assert_nothing_raised { su.file_name_format = '%y_%m.markdown' }
    assert_equal('%y_%m.markdown', su.file_name_format)
  end

  def test_header_date_format
    su = standup(@workdir)
    assert_equal('%Y-%m-%d', su.header_date_format)
    assert_nothing_raised { su.header_date_format = '%y-%m-%d' }
    assert_equal('%y-%m-%d', su.header_date_format)
  end

  def test_current_header
    su = standup(@workdir)
    assert_equal('Current', su.current_header)
    assert_nothing_raised { su.current_header = 'Today' }
    assert_equal('Today', su.current_header)
  end

  def test_previous_header
    su = standup(@workdir)
    assert_equal('Previous', su.previous_header)
    assert_nothing_raised { su.previous_header = 'Yesterday' }
    assert_equal('Yesterday', su.previous_header)
  end

  def test_impediments_header
    su = standup(@workdir)
    assert_equal('Impediments', su.impediments_header)
    assert_nothing_raised { su.impediments_header = 'Hold Ups' }
    assert_equal('Hold Ups', su.impediments_header)
  end

  def test_notes_header
    su = standup(@workdir)
    assert_equal('Notes', su.notes_header)
    assert_nothing_raised { su.notes_header = 'Remember' }
    assert_equal('Remember', su.notes_header)
  end

  # Booleans

  def test_file_written?
    su = standup(@workdir)
    refute(su.file_written?)
    assert_nothing_raised { su.write }
    assert(su.file_written?)
  end

  def test_entry_previously_added?
    su = standup(@workdir)
    refute(su.entry_previously_added?)
    create_standup_file(@current_test_file)
    su.load
    assert(su.entry_previously_added?)
  end

  def test_write
    su = standup(@workdir)
    assert_nothing_raised { su.write }
    assert(File.file?(@current_test_file))
  end

  def test_load
    su = standup(@workdir)
    assert_nothing_raised { su.load }
  end
end
