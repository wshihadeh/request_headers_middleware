# frozen_string_literal: true
require 'delayed_job'

module Delayed
  class PerformableMethod
    attr_accessor :object, :method_name, :args, :store

    def encode_with(coder)
      coder.map = {
        'object' => object,
        'method_name' => method_name,
        'args' => args,
        'store' => store
      }
    end
  end
end

class DelayedRequestHeadersPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:enqueue) do |job|
      obj = job.payload_object.dup
      obj.instance_variable_set(:@store, RequestHeadersMiddleware.store)
      job.payload_object = obj
    end

    lifecycle.before(:perform) do |worker, job|
      RequestHeadersMiddleware.store = job.payload_object.instance_variable_get(:@store)
      RequestHeadersMiddleware.tag_logger RequestHeadersMiddleware.delayed_logger
    end

    lifecycle.after(:perform) do |worker, job|
      RequestHeadersMiddleware.untag_logger RequestHeadersMiddleware.delayed_logger
      RequestHeadersMiddleware.store = {}
    end
  end
end

Delayed::Worker.plugins << DelayedRequestHeadersPlugin
