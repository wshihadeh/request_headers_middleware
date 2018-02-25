# frozen_string_literal: true
require 'request_headers_middleware/railtie' if defined?(Rails)
require 'request_headers_middleware/delayed_job' if defined?(Delayed)
require 'request_headers_middleware/message_queue' if defined?(MessageQueue)
require 'request_headers_middleware/configuration'
require 'request_headers_middleware/middleware'

module RequestHeadersMiddleware # :nodoc:
  extend self

  attr_accessor :blacklist, :whitelist, :callbacks
  @whitelist = ['x-request-id'.to_sym]
  @blacklist = []
  @callbacks = []
  @configuration = Configuration.new

  def self.configure
    yield @configuration
  end

  def self.delayed_logger
    @configuration.delayed_logger
  end

  def store
    RequestStore[:headers] ||= {}
  end

  def store=(store)
    RequestStore[:headers] = store
  end

  def tag_logger(logger)
    store.each do |key, value|
      logger&.push_tags(value) unless value.nil? || !logger.respond_to?(:push_tags)
    end
  end

  def untag_logger(logger)
    store.each do |key, value|
      logger&.pop_tags unless value.nil? || !logger.respond_to?(:pop_tags)
    end
  end

  def setup(config)
    if config.whitelist
      @whitelist = config.whitelist.map { |key| key.downcase.to_sym }
    end
    if config.blacklist
      @blacklist = config.blacklist.map { |key| key.downcase.to_sym }
    end
    config.callbacks && @callbacks = config.callbacks
  end
end
