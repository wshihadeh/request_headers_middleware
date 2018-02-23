# frozen_string_literal: true
require 'spec_helper'
require 'active_support'

describe RequestHeadersMiddleware::Middleware do
  let(:app) { MockRackApp.new }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(STDOUT)) }
  subject { described_class.new(app) }

  context 'when MockRackApp called with a request' do
    let(:env) do
      Rack::MockRequest.env_for('/some/path', 'HTTP_X_REQUEST_ID' => '1234',
                                              'HTTP_X_FORWARD' => '123',
                                              'HTTP_X_REQUEST_ID1' => '12',
                                              'CONTENT_TYPE' => 'text/plain')
    end

    it 'returns an empty Hash by default' do
      expect(RequestHeadersMiddleware.store).to eq({})
    end

    it 'assign a value for store and tag logger' do
      store = { 'X-Request-Id': 'ef382618-e46d-42f5-aca6-ae9e1db8fee0' }
      RequestHeadersMiddleware.store = store
      RequestHeadersMiddleware.tag_logger logger
      expect(RequestHeadersMiddleware.store[:'X-Request-Id']).to eq(store[:'X-Request-Id'])
      tags = logger.pop_tags(store.size)
      expect(tags.count).to eq(1)
      expect(tags.first).to eq(store[:'X-Request-Id'])
    end

    it 'reset the store and clear the tag from logger' do
      store = { 'X-Request-Id': 'ef382618-e46d-42f5-aca6-ae9e1db8fee0' }
      RequestHeadersMiddleware.store = store
      RequestHeadersMiddleware.tag_logger logger
      expect(RequestHeadersMiddleware.store[:'X-Request-Id']).to eq(store[:'X-Request-Id'])
      RequestHeadersMiddleware.untag_logger logger

      tags = logger.pop_tags(store.size)
      expect(tags.count).to eq(0)
      expect(tags).to eq([])
    end

    it 'only saves the X-Request-Id in RequestHeadersMiddleware.store' do
      subject.call(env)
      expect(app['CONTENT_TYPE']).to eq('text/plain')
      expect(RequestHeadersMiddleware.store).to match('X-Request-Id': '1234')
    end

    context 'with whitelist' do
      before do
        RequestHeadersMiddleware.whitelist = [:'x-forward']
        RequestHeadersMiddleware.blacklist = []
      end
      after do
        RequestHeadersMiddleware.whitelist = []
        RequestHeadersMiddleware.blacklist = []
      end

      it 'only saves the X-Forward in RequestHeadersMiddleware.store' do
        subject.call(env)
        expect(app['CONTENT_TYPE']).to eq('text/plain')
        expect(RequestHeadersMiddleware.store).to match('X-Forward': '123')
      end
    end

    context 'with blacklist' do
      before do
        RequestHeadersMiddleware.whitelist = []
        RequestHeadersMiddleware.blacklist = [:'x-forward']
      end
      after do
        RequestHeadersMiddleware.whitelist = []
        RequestHeadersMiddleware.blacklist = []
      end

      it 'only saves the X-Forward in RequestHeadersMiddleware.store' do
        subject.call(env)
        expect(app['CONTENT_TYPE']).to eq('text/plain')
        expect(RequestHeadersMiddleware.store)
          .to match('X-Request-Id1': '12', 'X-Request-Id': '1234')
      end
    end

    context 'with callbacks' do
      before do
        RequestHeadersMiddleware.whitelist = [:'x-request-id', :'x-request-id1']
        RequestHeadersMiddleware.blacklist = []
        RequestHeadersMiddleware.callbacks = [
          proc { |env| env['HTTP_X_REQUEST_ID'] = '4321' },
          proc { |env| env['HTTP_X_REQUEST_ID1'] = '21' }
        ]
      end
      after do
        RequestHeadersMiddleware.whitelist = []
        RequestHeadersMiddleware.blacklist = []
        RequestHeadersMiddleware.callbacks = nil
      end

      it 'only saves the X-Forward in RequestHeadersMiddleware.store' do
        subject.call(env)
        expect(app['CONTENT_TYPE']).to eq('text/plain')
        expect(app['HTTP_X_REQUEST_ID']).to eq('4321')
        expect(RequestHeadersMiddleware.store)
          .to match('X-Request-Id1': '12', 'X-Request-Id': '1234')
      end
    end
  end
end
