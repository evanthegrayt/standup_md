# frozen_string_literal: true

require "optparse"
require "standup_md/cli/helpers"

module StandupMD
  ##
  # Class for handling the command-line interface.
  class Cli
    include Helpers

    ##
    # Path to the bundled zsh completion script.
    #
    # @return [String]
    ZSH_COMPLETION_FILE = ::File.expand_path(
      ::File.join(__dir__, "..", "..", "completion", "zsh", "_standup")
    ).freeze

    ##
    # Access to the class's configuration.
    #
    # @return [StandupMD::Config::Cli]
    def self.config
      StandupMD.config.cli
    end

    ##
    # Prints output if +verbose+ is true.
    #
    # @return [nil]
    def self.echo(msg)
      puts msg if config.verbose
    end

    ##
    # Prints zsh completion setup instructions.
    #
    # @return [String]
    def self.zsh_completion_instructions
      completion_dir = ::File.dirname(ZSH_COMPLETION_FILE)

      <<~INSTRUCTIONS
        Zsh completion file:
          #{ZSH_COMPLETION_FILE}

        To load it directly, add this before compinit runs:

          fpath=("#{completion_dir}" $fpath)
          autoload -Uz compinit
          compinit

        Or symlink it into your own completion directory:

          mkdir -p ~/.zsh/completions
          ln -sf "#{ZSH_COMPLETION_FILE}" ~/.zsh/completions/_standup

        Then make sure that directory is in fpath before compinit runs:

          fpath=(~/.zsh/completions $fpath)
          autoload -Uz compinit
          compinit
      INSTRUCTIONS
    end

    ##
    # Creates an instance of +StandupMD+ and runs what the user requested.
    def self.execute(options = [])
      new(options).tap do |exe|
        if exe.zsh_completion_requested?
          puts zsh_completion_instructions
          next
        end

        exe.write_file if exe.write?
        if config.print
          exe.print(exe.entry)
        elsif config.post
          exe.post(exe.entry)
        elsif config.edit
          exe.edit
        end
      end
    end

    ##
    # The entry searched for, usually today.
    #
    # @return [StandupMD::Entry]
    attr_reader :entry

    ##
    # Arguments passed at runtime.
    #
    # @return [Array] ARGV
    attr_reader :options

    ##
    # The file loaded.
    #
    # @return [StandupMD::File]
    attr_reader :file

    ##
    # Was a file date argument passed?
    #
    # @return [Boolean]
    def file_date_argument?
      @file_date_argument
    end

    ##
    # Was zsh completion output requested?
    #
    # @return [Boolean]
    def zsh_completion_requested?
      @zsh_completion_requested
    end

    ##
    # Constructor. Sets defaults.
    #
    # @param [Array] options
    def initialize(options = [], load_config: true)
      @config = self.class.config
      @preference_file_loaded = false
      @file_date_argument = false
      @zsh_completion_requested = false
      @options = options
      return if load_zsh_completion_request(options)

      load_preferences if load_config
      load_runtime_preferences(options)
      return if zsh_completion_requested?

      @file = find_file
      @file&.load
      @entry = @file.nil? ? nil : new_entry(@file)
    end

    ##
    # Load the preference file.
    #
    # @return [nil]
    def load_preferences
      if ::File.exist?(@config.preference_file)
        ::StandupMD.load_config_file(@config.preference_file)
        @preference_file_loaded = true
      else
        echo "Preference file #{@config.preference_file} does not exist."
      end
    end

    ##
    # Has the preference file been loaded?
    #
    # @return [boolean]
    def preference_file_loaded?
      @preference_file_loaded
    end

    ##
    # Opens the file in an editor. Abandons the script.
    #
    # @return [nil]
    def edit
      echo "Opening file in #{@config.editor}"
      exec("#{@config.editor} #{file.name}")
    end

    ##
    # Writes entries to the file.
    #
    # @return [Boolean] true if file was written
    def write_file
      echo "Writing file #{file.name}"
      file.write
    end

    ##
    # Should the file be written?
    #
    # @return [Boolean]
    def write?
      !!(@config.write && !read_only? && entry)
    end

    ##
    # Should the CLI post the entry to a chat adapter?
    #
    # @return [Boolean]
    def post?
      @config.post
    end

    ##
    # Quick access to +Cli.echo+.
    #
    # @return [nil]
    def echo(msg)
      self.class.echo(msg)
    end

    private

    ##
    # Detects zsh completion setup requests before loading user preferences.
    #
    # @return [Boolean]
    def load_zsh_completion_request(options)
      return false unless options.include?("--zsh-completion")

      invalid_options = options - ["--zsh-completion"]
      raise OptionParser::InvalidArgument, invalid_options.join(" ") unless invalid_options.empty?

      @zsh_completion_requested = true
    end

    ##
    # Is this a read-only action?
    #
    # @return [Boolean]
    def read_only?
      @config.print || @config.post || file_date_argument?
    end

    ##
    # Finds the file, avoiding file creation for read-only actions.
    #
    # @return [StandupMD::File, nil]
    def find_file
      return StandupMD::File.find_by_date(@config.date) unless read_only?

      without_file_creation { StandupMD::File.find_by_date(@config.date) }
    rescue
      raise unless @config.print || @config.post

      nil
    end

    ##
    # Temporarily disables file creation while looking for a file.
    #
    # @return [StandupMD::File]
    def without_file_creation
      original_create = StandupMD.config.file.create
      StandupMD.config.file.create = false
      yield
    ensure
      StandupMD.config.file.create = original_create
    end
  end
end
