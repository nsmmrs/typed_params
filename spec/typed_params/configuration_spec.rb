# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Configuration do
  subject { TypedParams::Configuration.new }

  describe '#ignore_nil_optionals=' do
    it('should respond') { expect(subject).to respond_to :ignore_nil_optionals= }
  end

  describe '#ignore_nil_optionals' do
    it('should respond') { expect(subject).to respond_to :ignore_nil_optionals }
  end

  describe '#path_transform=' do
    it('should respond') { expect(subject).to respond_to :path_transform= }
  end

  describe '#path_transform' do
    it('should respond') { expect(subject).to respond_to :path_transform }
  end

  describe '#key_transform=' do
    it('should respond') { expect(subject).to respond_to :key_transform= }
  end

  describe '#key_transform' do
    it('should respond') { expect(subject).to respond_to :key_transform }
  end

  describe '#filtered_params=' do
    it('should respond') { expect(subject).to respond_to :filtered_params= }
  end

  describe '#filtered_params' do
    it('should respond') { expect(subject).to respond_to :filtered_params }

    it 'should default to Rails form internals' do
      expect(subject.filtered_params).to eq %i[authenticity_token _method]
    end
  end
end