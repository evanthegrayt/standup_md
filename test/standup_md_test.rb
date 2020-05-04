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
    @test_config = File.join(@workdir, 'standup_md.yml')
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
      StandupMD.load { |s| s.directory = @workdir }
    end
    su = StandupMD.load do |s|
      s.directory = @workdir
      s.bullet_character = '*'
    end
    assert_equal(@workdir, su.directory)
    assert_instance_of(StandupMD, su)
  end

  ##
  # The reload method should exist, and is an alias of +load+.
  def test_reload
    su = standup(@workdir)
    assert_respond_to(su, :reload)
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

  ##
  # Should be all entries before the current entry.
  def test_all_previous_entries
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(
      fixtures['previous_entry_tasks'],
      su.all_previous_entries
    )
  end

  ##
  # Directory should default be settable, and where standup files are read from.
  def test_directory
    su = standup(@workdir)
    assert_equal(@workdir, su.directory)
    assert_nothing_raised { su.directory = File.join(@workdir, 'TEST') }
    assert_equal(File.join(@workdir, 'TEST'), su.directory)
    assert(File.directory?(su.directory))
  end

  ##
  # The order of the subheaders is changeable, but all elements must exist.
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

  ##
  # Should be able to add tasks for current_entry.
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

  ##
  # Should be able to add impediments to the array.
  def test_impediments
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(["None"], su.impediments)
    assert_raise { su.impediments = ''}
    new_impediments = ['Impediment 1']
    assert_nothing_raised { su.impediments = new_impediments }
    assert_equal(new_impediments, su.impediments)
  end

  ##
  # Should be able to add notes to the array.
  def test_notes
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal([], su.notes)
    assert_raise { su.notes = ''}
    new_notes = ['Note 1']
    assert_nothing_raised { su.notes = new_notes }
    assert_equal(new_notes, su.notes)
  end

  ##
  # Should be able to change the bullet character but should raise if not * or -
  def test_bullet_character
    su = standup(@workdir)
    assert_equal('-', su.bullet_character)
    assert_nothing_raised { su.bullet_character = '*' }
    assert_equal('*', su.bullet_character)
    assert_raise { su.bullet_character = '>' }
  end

  ##
  # Should be an integer between +1..5+. If higher than +sub_header_depth+,
  # +sub_header_depth+ should be changed.
  def test_header_depth
    su = standup(@workdir)
    assert_equal(1, su.header_depth)
    assert_raise { su.header_depth = 6 }
    assert_raise { su.header_depth = 0 }
    assert_nothing_raised { su.header_depth = 3 }
    assert_equal(3, su.header_depth)
    assert_equal(4, su.sub_header_depth)
  end

  ##
  # Should be an integer between +2..6+. If lower than +header_depth+,
  # +header_depth+ should be changed.
  def test_sub_header_depth
    su = standup(@workdir)
    assert_equal(2, su.sub_header_depth)
    assert_raise { su.sub_header_depth = 1 }
    assert_raise { su.sub_header_depth = 7 }
    assert_nothing_raised { su.sub_header_depth = 6 }
    assert_equal(6, su.sub_header_depth)
    assert_nothing_raised { su.header_depth = 3 }
    assert_equal(3, su.header_depth)
    assert_nothing_raised { su.sub_header_depth = 3 }
    assert_equal(3, su.sub_header_depth)
    assert_equal(2, su.header_depth)
  end

  ##
  # Should be an array of previous entry's current entry.
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

  ##
  # Should be changeable, and return a string parsed by +strftime+.
  def test_file_name_format
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal('%Y_%m.md', su.file_name_format)
    assert_nothing_raised { su.file_name_format = '%y_%m.markdown' }
    assert_equal('%y_%m.markdown', su.file_name_format)
  end

  ##
  # Should be changeable, and return a string parsed by +strftime+.
  def test_header_date_format
    su = standup(@workdir)
    assert_equal('%Y-%m-%d', su.header_date_format)
    assert_nothing_raised { su.header_date_format = '%y-%m-%d' }
    assert_equal('%y-%m-%d', su.header_date_format)
  end

  ##
  # Should be changeable and used as the header for +current_entry+
  def test_current_header
    su = standup(@workdir)
    assert_equal('Current', su.current_header)
    assert_nothing_raised { su.current_header = 'Today' }
    assert_equal('Today', su.current_header)
  end

  ##
  # Should be changeable and used as the header for +previous_entry+
  def test_previous_header
    su = standup(@workdir)
    assert_equal('Previous', su.previous_header)
    assert_nothing_raised { su.previous_header = 'Yesterday' }
    assert_equal('Yesterday', su.previous_header)
  end

  ##
  # Should be changeable and used as the header for +impediments+
  def test_impediments_header
    su = standup(@workdir)
    assert_equal('Impediments', su.impediments_header)
    assert_nothing_raised { su.impediments_header = 'Hold Ups' }
    assert_equal('Hold Ups', su.impediments_header)
  end

  ##
  # Should be changeable and used as the header for +notes+
  def test_notes_header
    su = standup(@workdir)
    assert_equal('Notes', su.notes_header)
    assert_nothing_raised { su.notes_header = 'Remember' }
    assert_equal('Remember', su.notes_header)
  end

  # Booleans

  ##
  # Should be false when first instantiated, true after +write+ is called.
  def test_file_written?
    su = standup(@workdir)
    refute(su.file_written?)
    assert_nothing_raised { su.write }
    assert(su.file_written?)
  end

  ##
  # Should be true if +current_entry+ was in the file at the time it was read.
  def test_entry_previously_added?
    su = standup(@workdir)
    refute(su.entry_previously_added?)
    create_standup_file(@current_test_file)
    su.load
    assert(su.entry_previously_added?)
  end

  ##
  # Should write the file.
  def test_write
    su = standup(@workdir)
    assert_nothing_raised { su.write }
    assert(File.file?(@current_test_file))
  end

  ##
  # Should load instance variables.
  def test_load
    su = StandupMD.new { |s| s.directory = @workdir }
    assert_nil(su.instance_variable_get('@today'))
    assert_nothing_raised { su.load }
    refute_nil(su.instance_variable_get('@today'))
  end

  ##
  # Should be false until config file is loaded.
  def test_config_file_loaded?
    su = standup(@workdir)
    refute(su.config_file_loaded?)
    assert_raise { su.load_config_file }

    create_config_file(@test_config)
    su = StandupMD.new(@test_config) { |s| s.directory = @workdir }
    assert_nothing_raised { su.load_config_file }
    assert(su.config_file_loaded?)
  end

  ##
  # Config should be a hash, and populated if +config_file+ is loaded.
  def test_config
    su = standup(@workdir)
    create_config_file(@test_config)
    assert_empty(su.config)
    assert_nothing_raised { su.config_file = @test_config }
    assert_nothing_raised { su.load_config_file }
    assert_equal({'impediments' => ['NONE']}, su.config)
  end

  ##
  # Config file should be settable and gettable.
  def test_config_file
    su = standup(@workdir)
    assert_nil(su.config_file)
    assert_nothing_raised { su.config_file = @test_config }
    assert_equal(@test_config, su.config_file)
  end

  ##
  # Should raise if +config_file+ wasn't set or if file doesn't exist.
  def test_load_config_file
    assert_raise { StandupMD.new(@test_config) { |s| s.directory = @workdir } }
    su = standup(@workdir)
    assert_nothing_raised { su.config_file = @test_config }
    assert_raise { su.load_config_file }
    create_config_file(@test_config)
    assert_nothing_raised { su.load_config_file }
    assert_equal(['NONE'], su.impediments)
  end
end
