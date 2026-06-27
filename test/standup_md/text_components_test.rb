# frozen_string_literal: true

require_relative "../test_helper"

class TestTextComponents < TestHelper
  def setup
    super
    StandupMD.config.file.reset
  end

  def test_task
    task = StandupMD::Task.new("Supporting task", indent_level: 1)

    assert_equal("Supporting task", task.to_s)
  end

  def test_section
    section = StandupMD::Section.new(
      :current,
      [
        "Main task",
        StandupMD::Task.new("Supporting task", indent_level: 1)
      ]
    )

    assert_equal("current", section.to_s)
    assert_equal(:current, section.type)
    assert_equal(["Main task", "Supporting task"], section.tasks.map(&:to_s))
    assert_equal([0, 1], section.tasks.map(&:indent_level))
  end
end
