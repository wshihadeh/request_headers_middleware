# frozen_string_literal: true
require 'message_queue'

class MessageQueueRequestHeadersPlugin < MessageQueue::Plugin
  def self.symbolize(obj = {})
    if obj.is_a? Hash
      return obj.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = symbolize(v) }
      end
    end
    obj
  end

  callbacks do |lifecycle|
    lifecycle.before(:publish) do |_message, options|
      store = { store: RequestHeadersMiddleware.store }
      options[:headers] = options.fetch(:headers, {}).merge(store)
    end

    lifecycle.before(:consume) do |delivery_info, properties, payload|
      headers = symbolize(properties.headers)
      RequestHeadersMiddleware.store = headers[:store]
      RequestHeadersMiddleware.tag_logger MessageQueue.logger
    end

    lifecycle.after(:consume) do |delivery_info, properties, payload|
      RequestHeadersMiddleware.untag_logger MessageQueue.logger
    end
  end
end

MessageQueue.plugins << MessageQueueRequestHeadersPlugin
