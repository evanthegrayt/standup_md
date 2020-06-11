module StandupMD
  class Config

    ##
    # The configuration class for StandupMD::File
    class File
      ##
      # Number of octothorps that should preface entry headers.
      #
      # @return [Integer] between 1 and 5
      #
      # @default 1
      attr_reader :header_depth

      ##
      # Number of octothorps that should preface sub-headers.
      #
      # @return [Integer] between 2 and 6
      #
      # @default 2
      attr_reader :sub_header_depth

      ##
      # The directory in which the files are located.
      #
      # @return [String]
      #
      # @default "~/.cache/standup_md"
      attr_reader :directory

      ##
      # Character used as bullets for list entries.
      #
      # @return [String] either - (dash) or * (asterisk)
      #
      # @default "-" (dash)
      attr_reader :bullet_character

      ##
      # String to be used as "Current" header.
      #
      # @param [String] header
      #
      # @return [String]
      #
      # @default "Current"
      attr_accessor :current_header

      ##
      # String to be used as "Previous" header.
      #
      # @param [String] header
      #
      # @return [String]
      #
      # @default "Previous"
      attr_accessor :previous_header

      ##
      # String to be used as "Impediments" header.
      #
      # @param [String] header
      #
      # @return [String]
      #
      # @default "Impediments"
      attr_accessor :impediments_header

      ##
      # String to be used as "Notes" header.
      #
      # @param [String] header
      #
      # @return [String]
      #
      # @default "Notes"
      attr_accessor :notes_header

      ##
      # Preferred order for sub-headers.
      #
      # @param [Array] sub_header_order
      #
      # @return [Array]
      #
      # @default %w[previous current impediment notes]
      attr_accessor :sub_header_order

      ##
      # Format to be used for standup file names. Should be parse-able by
      # strftime, and should be a monthly date.
      #
      # @param [String] name_format
      #
      # @return [String]
      #
      # @default "%Y_%m.md"
      attr_accessor :name_format

      ##
      # The date format for entry headers. Will be parsed by +strftime+.
      #
      # @param [String] format
      #
      # @return [String]
      attr_accessor :header_date_format

      ##
      # Should the file be created if it doesn't exist?
      #
      # @param [Boolean] create
      #
      # @return [boolean]
      attr_accessor :create

      ##
      # Initializes the config with default values.
      def initialize
        reset_values
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Boolean] true if successful
      def reset_values
        @header_date_format = '%Y-%m-%d'
        @header_depth = 1
        @sub_header_depth = 2
        @current_header = 'Current'
        @previous_header = 'Previous'
        @impediments_header = 'Impediments'
        @notes_header = 'Notes'
        @sub_header_order = %w[previous current impediments notes]
        @directory = ::File.join(ENV['HOME'], '.cache', 'standup_md')
        @bullet_character = '-'
        @name_format = '%Y_%m.md'
        @create = true
        true
      end

      ##
      # Number of octothorps (#) to use before the main header.
      #
      # @param [Integer] depth
      #
      # @return [Integer]
      def header_depth=(depth)
        if !depth.between?(1, 5)
          raise 'Header depth out of bounds (1..5)'
        elsif depth >= sub_header_depth
          @sub_header_depth = depth + 1
        end
        @header_depth = depth
      end

      ##
      # Number of octothorps (#) to use before sub headers (Current, Previous,
      # etc).
      #
      # @param [Integer] depth
      #
      # @return [Integer]
      def sub_header_depth=(depth)
        if !depth.between?(2, 6)
          raise 'Sub-header depth out of bounds (2..6)'
        elsif depth <= header_depth
          @header_depth = depth - 1
        end
        @sub_header_depth = depth
      end

      ##
      # Setter for bullet_character. Must be * (asterisk) or - (dash).
      #
      # @param [String] character
      #
      # @return [String]
      def bullet_character=(char)
        raise 'Must be "-" or "*"' unless %w[- *].include?(char)
        @bullet_character = char
      end

      ##
      # Setter for directory. Must be expanded in case the user uses `~` for home.
      # If the directory doesn't exist, it will be created. To reset instance
      # variables after changing the directory, you'll need to call load.
      #
      # @param [String] directory
      #
      # @return [String]
      def directory=(directory)
        directory = ::File.expand_path(directory)
        FileUtils.mkdir_p(directory) unless ::File.directory?(directory)
        @directory = directory
      end
    end
  end
end
