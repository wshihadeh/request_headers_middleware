# frozen_string_literal: true
module RequestHeadersMiddleware
  class Configuration
    CONFIG_KEYS = [
      :delayed_logger, # [Logger used by delayed jobs]
    ].freeze

    attr_accessor :hash

    def initialize
      @hash = {}
    end

    def []=(key, value)
      raise InvalidKey, key unless CONFIG_KEYS.include?(key)

      @hash[key] = value
    end

    def [](key)
      @hash[key]
    end

    def delayed_logger
      @hash[:delayed_logger] || build_logger
    end

    private

    def build_logger
      return ::Rails.logger if defined?(Rails)
      raise 'Please define delayed_logger'
    end
  end
end
