require 'test/unit'
require 'fileutils'
require_relative File.join(__dir__, '..', 'lib', 'standup_md')

class TestName < Test::Unit::TestCase
  def setup
    @workdir = File.join(__dir__, 'files')
    FileUtils.mkdir(@workdir)
    @standup = StandupMD.new
    @standup.directory = @workdir
  end

  def teardown
    FileUtils.rmdir_r(@workdir)
  end

  def test_file
    assert_equal(File.expand_path(File.join(__dir__, 'files'`)))
  end
end
