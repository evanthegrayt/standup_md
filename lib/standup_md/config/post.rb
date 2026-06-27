# frozen_string_literal: true

require "standup_md/post"

module StandupMD
  class Config
    ##
    # The configuration class for chat posting.
    class Post
      ##
      # The default posting options.
      #
      # @return [Hash]
      DEFAULTS = {
        default_adapter: :slack
      }.freeze

      ##
      # Attributes copied into request-scoped config snapshots.
      #
      # @return [Array<Symbol>]
      CONFIG_ATTRIBUTES = DEFAULTS.keys.freeze

      ##
      # The adapter used when `standup --post` is called without a platform.
      #
      # @return [Symbol]
      attr_accessor :default_adapter

      ##
      # Registered adapter classes or instances.
      #
      # @return [Hash]
      attr_reader :adapters

      ##
      # Non-secret adapter options.
      #
      # @return [Hash]
      attr_reader :adapter_options

      ##
      # Initializes the config with default values.
      def initialize
        reset
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Hash]
      def reset
        DEFAULTS.each { |k, v| instance_variable_set("@#{k}", v) }
        @adapters = {}
        @adapter_options = Hash.new { |hash, key| hash[key] = {} }
        register_adapter(:slack, StandupMD::Post::Adapters::Slack)
        DEFAULTS
      end

      ##
      # Copies values from another post config.
      #
      # @param [StandupMD::Config::Post] config
      #
      # @return [StandupMD::Config::Post]
      def copy_from(config)
        CONFIG_ATTRIBUTES.each do |attribute|
          instance_variable_set("@#{attribute}", config.public_send(attribute))
        end
        @adapters = config.adapters.dup
        @adapter_options = Hash.new { |hash, key| hash[key] = {} }
        config.adapter_options.each do |name, options|
          @adapter_options[name] = options.dup
        end
        self
      end

      ##
      # Registers a posting adapter.
      #
      # @param name [String, Symbol]
      # @param adapter [Class, Object]
      #
      # @return [Class, Object]
      def register_adapter(name, adapter)
        adapters[name.to_sym] = adapter
      end

      ##
      # Configures non-secret adapter options.
      #
      # @param name [String, Symbol]
      # @param options [Hash]
      #
      # @return [Hash]
      def configure_adapter(name, options = {})
        options_for(name).merge!(symbolize_keys(options))
      end

      ##
      # Returns non-secret options for an adapter.
      #
      # @param name [String, Symbol]
      #
      # @return [Hash]
      def options_for(name)
        adapter_options[name.to_sym]
      end

      ##
      # Builds the adapter requested by name.
      #
      # @param name [String, Symbol, nil]
      #
      # @return [Object]
      def build_adapter(name = nil)
        adapter_name = (name || default_adapter).to_sym
        adapter = adapters.fetch(adapter_name) do
          raise StandupMD::Post::UnknownAdapter, "No post adapter registered for #{adapter_name}"
        end
        return adapter unless adapter.respond_to?(:new)
        return adapter.new if adapter.instance_method(:initialize).arity.zero?

        adapter.new(options_for(adapter_name))
      end

      private

      def symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[key.to_sym] = value
        end
      end
    end
  end
end
