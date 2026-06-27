# frozen_string_literal: true

require "standup_md/config/cli"
require "standup_md/config/file"
require "standup_md/config/entry"
require "standup_md/config/entry_list"
require "standup_md/config/post"

module StandupMD
  ##
  # This class provides a connector from StandupMD to the configuration classes.
  class Config
    ##
    # Reader for Cli config.
    #
    # @return [StandupMD::Config::Cli]
    attr_reader :cli

    ##
    # Reader for File config.
    #
    # @return [StandupMD::Config::File]
    attr_reader :file

    ##
    # Reader for Entry config.
    #
    # @return [StandupMD::Config::Entry]
    attr_reader :entry

    ##
    # Reader for EntryList config.
    #
    # @return [StandupMD::Config::EntryList]
    attr_reader :entry_list

    ##
    # Reader for Post config.
    #
    # @return [StandupMD::Config::Post]
    attr_reader :post

    ##
    # Builds the links to the configuration classes.
    def initialize
      @cli = StandupMD::Config::Cli.new
      @file = StandupMD::Config::File.new
      @entry = StandupMD::Config::Entry.new
      @entry_list = StandupMD::Config::EntryList.new
      @post = StandupMD::Config::Post.new
    end

    ##
    # Builds an independent snapshot of the current configuration.
    #
    # @return [StandupMD::Config]
    def copy
      self.class.new.tap do |config|
        config.cli.copy_from(cli)
        config.file.copy_from(file)
        config.entry.copy_from(entry)
        config.entry_list.copy_from(entry_list)
        config.post.copy_from(post)
      end
    end
  end
end
