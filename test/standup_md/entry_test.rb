require_relative '../test_helper'
require_relative '../../lib/standup_md'

class TestEntry < TestHelper
  def setup
    super
    @entry_one = StandupMD::Entry.new(
      Date.today,
      ['Current task'],
      ['Previous task'],
      ['Impediment'],
    )
    @entry_two = StandupMD::Entry.new(
      Date.today.prev_day,
      ['Current task'],
      ['Previous task'],
      ['Impediment'],
      ['Notes'],
    )
  end

  def test_create
    assert_nothing_raised do
      StandupMD::Entry.create { |s| s.current = ['testing'] }
    end
    assert_instance_of(StandupMD::Entry, StandupMD::Entry.create)
    standup = StandupMD::Entry.create { |s| s.current = ['testing'] }
    assert_equal(['testing'], standup.current)
  end

  def test_current
    assert_equal(['Current task'], @entry_one.current)
    @entry_one.current = ['test']
    assert_equal(['test'], @entry_one.current)
  end

  def test_previous
    assert_equal(['Previous task'], @entry_one.previous)
    @entry_one.previous = ['test']
    assert_equal(['test'], @entry_one.previous)
  end

  def test_impediments
    assert_equal(['Impediment'], @entry_one.impediments)
    @entry_one.impediments = ['test']
    assert_equal(['test'], @entry_one.impediments)
  end

  def test_notes
    assert_equal([], @entry_one.notes)
    @entry_one.notes = ['test']
    assert_equal(['test'], @entry_one.notes)
  end

  def test_date
    assert_equal(Date.today, @entry_one.date)
    @entry_one.date = ['test']
    assert_equal(['test'], @entry_one.date)
  end

  def test_to_h
    assert_instance_of(Hash, @entry_one.to_h)
    assert_equal(
      {
        Date.today => {
          'current'     => ['Current task'],
          'impediments' => ['Impediment'],
          'notes'       => [],
          'previous'    => ['Previous task']
        }
      },
      @entry_one.to_h
    )
  end

  def test_to_json
    assert_instance_of(String, @entry_one.to_json)
    assert_equal(
      "{\"#{Date.today}\":{\"current\":[\"Current task\"],\"previous\":" \
      "[\"Previous task\"],\"impediments\":[\"Impediment\"],\"notes\":[]}}",
      @entry_one.to_json
    )
  end
end
