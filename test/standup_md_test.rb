require_relative '../lib/standup_md'
require_relative 'test_helper'

class TestStandupMD < Test::Unit::TestCase
  include TestHelper

  def setup
    @workdir = File.join(__dir__, 'files')
    @current_test_file =
      File.join(@workdir, Date.today.strftime('%Y_%m') << '.md')
    @previous_month_test_file =
      File.join(@workdir, Date.today.prev_month.strftime('%Y_%m') << '.md')
  end

  def teardown
    FileUtils.rm_r(@workdir) if File.directory?(@workdir)
    FileUtils.rm(@current_test_file) if File.file?(@current_test_file)
  end

  def test_VERSION
    assert_match(/\d\.\d.\d/, ::StandupMD::VERSION)
  end

  def test_file
    su = standup(@workdir)
    assert_equal(@current_test_file, su.file)
  end

  def test_previous_file
    su = standup(@workdir)
    assert_equal('', su.previous_file)
    FileUtils.touch(@previous_month_test_file)
    assert_nothing_raised { su.reload! }
    assert_equal(@previous_month_test_file, su.previous_file)
  end

  def test_current_entry
    # TODO WHY IS THERE A BLANK ELEMENT?!
    # create_standup_file(@current_test_file)
    # su = standup(@workdir)
    # assert_equal(fixtures['current_entry'], su.current_entry)
    # TODO Make sure this reloads after reload!
  end

  def test_previous_entry
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(fixtures['previous_entry'], su.previous_entry)
    # TODO Make sure this reloads after reload!
  end

  def test_all_previous_entries
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(
      [fixtures['previous_entry'], '', fixtures['current_entry']].flatten,
      su.all_previous_entries
    )
  end

  def test_directory
    su = standup(@workdir)
    assert_equal(@workdir, su.directory)
    assert_nothing_raised do
      su.directory = File.join(@workdir, 'TEST')
    end
    assert(File.directory?(su.directory))
  end

  def test_current_entry_tasks
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], su.current_entry_tasks)
    assert_raise { su.current_entry_tasks = ''}
    new_tasks = ['test 100', 'test 99']
    assert_nothing_raised { su.current_entry_tasks = new_tasks }
    assert_equal(new_tasks, su.current_entry_tasks)
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

  def test_bullet_character
    su = standup(@workdir)
    assert_equal('-', su.bullet_character)
    assert_nothing_raised { su.bullet_character = '*' }
    assert_equal('*', su.bullet_character)
    assert_raise { su.bullet_character = '>' }
  end

  def test_file_name_format
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal('%Y_%m.md', su.file_name_format)
    assert_nothing_raised { su.file_name_format = '%y_%m.markdown' }
    assert_equal('%y_%m.markdown', su.file_name_format)
  end

  def test_entry_header_format
    su = standup(@workdir)
    assert_equal('# %Y-%m-%d', su.entry_header_format)
    assert_nothing_raised { su.entry_header_format = '# %y-%m-%d' }
    assert_equal('# %y-%m-%d', su.entry_header_format)
  end

  def test_current_header
    su = standup(@workdir)
    assert_equal('## Today', su.current_header)
    assert_nothing_raised { su.current_header = '## Current' }
    assert_equal('## Current', su.current_header)
  end

  def test_previous_header
    su = standup(@workdir)
    assert_equal('## Previous', su.previous_header)
    assert_nothing_raised { su.previous_header = '## Yesterday' }
    assert_equal('## Yesterday', su.previous_header)
  end

  def test_impediment_header
    su = standup(@workdir)
    assert_equal('## Impediments', su.impediment_header)
    assert_nothing_raised { su.impediment_header = '## Hold Ups' }
    assert_equal('## Hold Ups', su.impediment_header)
  end

  def test_previous_entry_tasks
    create_standup_file(@current_test_file)
    su = standup(@workdir)
    assert_equal(["- Test task 2", "- Test task 4"], su.previous_entry_tasks)
  end

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
    # TODO
    su.reload!
    # assert(su.entry_previously_added?)
  end

  def test_write
    su = standup(@workdir)
    assert_nothing_raised { su.write }
    refute(su.write)
    assert(File.file?(@current_test_file))
  end

  def test_reload!
    su = standup(@workdir)
    assert_nothing_raised { su.reload! }
  end
end
