# frozen_string_literal: true
require 'spec_helper'

describe Delayed::PerformableMethod do
  it 'has store attr_accessor' do
    instance_methods = Delayed::PerformableMethod.instance_methods
    expect(instance_methods.include?(:store)).to eq(true)
    expect(instance_methods.include?(:store=)).to eq(true)
  end

  it 'set store' do
    dj = Delayed::PerformableMethod.new(User.new, :send_email, {})
    dj.store = { 'x-request-id': '101010' }

    expect(dj.instance_variables).to eq(
      [:@object, :@args, :@method_name, :@store]
    )
    expect(dj.object.class).to eq(User)
    expect(dj.method_name).to eq(:send_email)
    expect(dj.instance_variable_defined?(:@store)).to eq(true)
    expect(dj.instance_variable_get(:@store)).to eq('x-request-id': '101010')
    expect(dj.store[:'x-request-id']).to eq('101010')
  end
end
