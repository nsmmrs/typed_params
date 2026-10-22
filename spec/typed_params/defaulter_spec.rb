# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Defaulter do
  def process(schema, value, controller: nil)
    params = TypedParams::Parameterizer.new(schema:).call(value:)

    TypedParams::Processor.new(schema:, controller:).call(params)

    params
  end

  it 'should apply a static default when missing' do
    schema = TypedParams::Schema.new(type: :hash) { param :role, type: :string, default: 'user' }

    params = process(schema, {})

    expect(params[:role].value).to eq 'user'
  end

  it 'should apply a proc default when missing' do
    schema = TypedParams::Schema.new(type: :hash) { param :role, type: :string, default: -> { 'user' } }

    params = process(schema, {})

    expect(params[:role].value).to eq 'user'
  end

  it 'should call proc defaults per request' do
    n      = 0
    schema = TypedParams::Schema.new(type: :hash) { param :n, type: :integer, default: -> { n += 1 } }

    process(schema, {})
    params = process(schema, {})

    expect(params[:n].value).to eq 2
  end

  it 'should not share mutable defaults between requests' do
    schema = TypedParams::Schema.new(type: :hash) { param :tags, type: :array, allow_blank: true, default: [] }

    first  = process(schema, {})
    first[:tags].value << 'admin'
    second = process(schema, {})

    expect(second[:tags].value).to eq []
  end

  it 'should not share nested mutable defaults between requests' do
    default = { 'roles' => ['user'] }
    schema  = TypedParams::Schema.new(type: :hash) { param :meta, type: :hash, allow_non_scalars: true, default: }

    first = process(schema, {})
    first[:meta].value['roles'] << 'admin'

    expect(default).to eq('roles' => ['user'])
    expect(process(schema, {})[:meta].value).to eq('roles' => ['user'])
  end

  it 'should not clobber explicit nil' do
    schema = TypedParams::Schema.new(type: :hash) { param :role, type: :string, allow_nil: true, default: 'user' }

    params = process(schema, { role: nil })

    expect(params[:role].value).to be nil
  end

  it 'should not clobber explicit false' do
    schema = TypedParams::Schema.new(type: :hash) { param :flag, type: :boolean, default: true }

    params = process(schema, { flag: false })

    expect(params[:flag].value).to be false
  end

  it 'should not clobber explicit blank' do
    schema = TypedParams::Schema.new(type: :hash) { param :name, type: :string, allow_blank: true, default: 'user' }

    params = process(schema, { name: '' })

    expect(params[:name].value).to eq ''
  end

  it 'should satisfy required params' do
    schema = TypedParams::Schema.new(type: :hash) { param :role, type: :string, default: 'user' }

    expect { process(schema, {}) }.to_not raise_error
  end

  it 'should coerce defaults' do
    schema = TypedParams::Schema.new(type: :hash) { param :n, type: :integer, coerce: true, default: '5' }

    params = process(schema, {})

    expect(params[:n].value).to eq 5
  end

  it 'should validate defaults' do
    schema = TypedParams::Schema.new(type: :hash) { param :role, type: :string, inclusion: { in: %w[user admin] }, default: 'root' }

    expect { process(schema, {}) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should transform defaults' do
    schema = TypedParams::Schema.new(type: :hash) { param :name, type: :string, default: 'user', transform: -> k, v { [k, v.upcase] } }

    params = process(schema, {})

    expect(params[:name].value).to eq 'USER'
  end

  it 'should apply nested defaults' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :user, type: :hash do
        param :role, type: :string, default: 'user'
      end
    end

    params = process(schema, { user: {} })

    expect(params[:user][:role].value).to eq 'user'
  end

  it 'should apply defaults inside a defaulted parent' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :user, type: :hash, default: {} do
        param :role, type: :string, default: 'user'
      end
    end

    params = process(schema, {})

    expect(params[:user][:role].value).to eq 'user'
  end

  it 'should not materialize a missing parent from child defaults' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :user, type: :hash, optional: true do
        param :role, type: :string, default: 'user'
      end
    end

    params = process(schema, {})

    expect(params[:user]).to be nil
  end

  it 'should skip defaults for guarded-out params' do
    controller = Object.new
    def controller.admin? = false

    schema = TypedParams::Schema.new(type: :hash) { param :role, type: :string, optional: true, default: 'user', if: :admin? }

    params = process(schema, {}, controller:)

    expect(params[:role]).to be nil
  end

  it 'should raise on non-zero-arity proc defaults' do
    expect {
      TypedParams::Schema.new(type: :hash) { param :role, type: :string, default: -> v { v } }
    }.to raise_error ArgumentError
  end

  it 'should raise on root defaults' do
    expect {
      TypedParams::Schema.new(type: :hash, default: {})
    }.to raise_error ArgumentError
  end

  it 'should raise on endless items defaults' do
    expect {
      TypedParams::Schema.new(type: :array) { items type: :string, default: 'user' }
    }.to raise_error ArgumentError
  end
end
