require 'json'
require 'yaml'
require 'optparse'
require_relative 'standup_md'

class Cli

  USER_PREFERENCES =
    File.expand_path(File.join(ENV['HOME'], '.standup_md.yml')).freeze

  attr_reader :options, :additions, :preferences

  def initialize(options)
    @additions = nil
    @today = false
    @json = false
    @all = false
    @verbose = false
    @write = true
    @edit = true
    @previous_append = true
    @preferences = get_preferences(options)
  end

  def execute
    editor = preferences.delete('editor') || determine_editor

    if preferences.key?('previous_entry_tasks') && previous_append?
      @additions = preferences.delete('previous_entry_tasks')
    end

    standup = ::StandupMD.new do |s|
      puts "Runtime options:" if verbose?
      preferences.each do |k, v|
        if s.respond_to?(k)
          puts "  #{k} = #{v}" if verbose?
          s.send("#{k}=", v)
        else
          puts "Method `Standup##{k}=` does not exist"
        end
      end
    end.load

    puts 'Status:' if verbose?

    if additions
      puts 'Appending previous entry tasks' if verbose?
      standup.previous_entry_tasks.concat(additions)
    end

    if today?
      puts "Display today's entry" if verbose?
      puts '  ...as json' if json? && verbose?
      entry = standup.current_entry
      puts json? ? entry.to_json : entry
    end

    if all?
      puts "Display all entries" if verbose?
      if json?
        puts '  ...as json' if verbose?
        puts standup.all_entries.to_json
      else
        standup.all_entries.each do |head, s_heads|
          puts '#' * standup.header_depth + ' ' + head
          s_heads.each do |s_head, tasks|
            puts '#' * standup.sub_header_depth + ' ' + s_head
            tasks.each { |task| puts standup.bullet_character + ' ' + task }
          end
          puts
        end
      end
    end

    if write?
      puts '  Writing file' if verbose?
      standup.write
    end

    if edit?
      puts "  Opening file in #{editor}" if verbose?
      exec("#{editor} #{standup.file}")
    end

    puts "Done!" if verbose?
  end

  private

  def determine_editor
    return ENV['VISUAL'] if ENV['VISUAL']
    return ENV['EDITOR'] if ENV['EDITOR']
    'vim'
  end

  def today?
    @today
  end

  def json?
    @json
  end

  def all?
    @all
  end

  def verbose?
    @verbose
  end

  def write?
    @write
  end

  def edit?
    @edit
  end

  def previous_append?
    @previous_append
  end

  def preferences
    @preferences
  end

  def get_preferences(options)
    prefs = {}

    OptionParser.new do |opts|
      opts.banner = 'The Standup Doctor'
      opts.version = ::StandupMD::VERSION
      opts.on('--current-entry-tasks=ARRAY', Array, "List of today's tasks") do |v|
        prefs['current_entry_tasks'] = v
      end
      opts.on('--previous-entry-tasks=ARRAY', Array, "List of yesterday's tasks") do |v|
        prefs['previous_entry_tasks'] = v
      end
      opts.on('--impediments=ARRAY', Array, 'List of impediments for today') do |v|
        prefs['impediments'] = v
      end
      opts.on('--notes=ARRAY', Array, 'List of notes for today') do |v|
        prefs['notes'] = v
      end
      opts.on('--sub-header-order=ARRAY', Array, 'The order of the sub-headers when writing the file') do |v|
        prefs['sub_header_order'] = v
      end
      opts.on('--[no-]previous-append', 'Append previous tasks? Default is true') do |v|
        @previous_append = v
      end
      opts.on('-f', '--file-name-format=STRING', 'Date-formattable string to use for standup file name') do |v|
        prefs['file_name_format'] = v
      end
      opts.on('-e', '--editor=EDITOR', 'Editor to use for opening standup files') do |v|
        prefs['editor'] = v
      end
      opts.on('-d', '--directory=DIRECTORY', 'The directories where standup files are located') do |v|
        prefs['directory'] = v
      end
      opts.on('--[no-]write', "Write today's entry if it doesn't exist. Default is true") do |v|
        @write = v
      end
      opts.on('--[no-]edit', 'Open the file in the editor. Default is true') do |v|
        @edit = v
      end
      opts.on('-j', '--[no-]json', 'Display output as formatted json. Default is false.') do |v|
        @json = v
      end
      opts.on('-v', '--[no-]verbose', 'Verbose output. Default is false.') do |v|
        @verbose = v
      end
      opts.on('-t', '--today', "Display today's entry. Disables editing") do |v|
        @today = v
        @edit = false
      end
      opts.on('-a', '--all', "Display all previous entries. Disables editing") do |v|
        @all = v
        @edit = false
      end
    end.parse!(options)

    (File.file?(USER_PREFERENCES) ? YAML.load_file(USER_PREFERENCES) : {}).merge(prefs)
  end
end
