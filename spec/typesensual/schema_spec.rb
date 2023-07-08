# frozen_string_literal: true

RSpec.describe Typesensual::Schema do
  subject { described_class.new {} }

  describe '#initialize' do
    it 'evaluates the block in the context of the instance' do
      expect { |b|
        described_class.new(&b)
      }.to yield_with_args(an_instance_of(described_class))
    end
  end

  describe '#field' do
    context 'with nothing but a string name' do
      it 'defines a field with the given name and auto type' do
        subject.field 'foo'

        expect(subject.to_h['fields']).to include(a_hash_including(
          'name' => 'foo',
          'type' => 'auto'
        ))
      end
    end

    context 'with a regexp name' do
      it 'defines a field with an (unwrapped) regex name' do
        subject.field(/foo.*/)

        expect(subject.to_h['fields']).to include(a_hash_including(
          'name' => 'foo.*'
        ))
      end
    end

    context 'with a type' do
      it 'defines a field with that type' do
        subject.field :foo, type: 'string'

        expect(subject.to_h['fields']).to include(a_hash_including(
          'name' => 'foo',
          'type' => 'string'
        ))
      end
    end

    it 'passes through facet: true' do
      subject.field :foo, facet: true

      expect(subject.to_h['fields']).to include(a_hash_including(
        'name' => 'foo',
        'facet' => true
      ))
    end

    it 'passes through locale: values' do
      subject.field :foo, locale: 'ja'

      expect(subject.to_h['fields']).to include(a_hash_including(
        'name' => 'foo',
        'locale' => 'ja'
      ))
    end

    it 'passes through index: false' do
      subject.field :foo, index: false

      expect(subject.to_h['fields']).to include(a_hash_including(
        'name' => 'foo',
        'index' => false
      ))
    end

    it 'passes through optional: true' do
      subject.field :foo, optional: true

      expect(subject.to_h['fields']).to include(a_hash_including(
        'name' => 'foo',
        'optional' => true
      ))
    end
  end

  describe '#token_separators' do
    it 'sets the token_separators value' do
      subject.token_separators ' ', '-', '_'

      expect(subject.to_h['token_separators']).to eq([' ', '-', '_'])
    end
  end

  describe '#symbols_to_index' do
    it 'sets the symbols_to_index value' do
      subject.symbols_to_index '%', '$'

      expect(subject.to_h['symbols_to_index']).to eq(['%', '$'])
    end
  end

  describe '#default_sorting_field' do
    it 'sets the default_sorting_field value' do
      subject.default_sorting_field :foo

      expect(subject.to_h['default_sorting_field']).to eq('foo')
    end
  end

  describe '#enable_nested_fields' do
    it 'sets the enable_nested_fields value to whatever was provided' do
      subject.enable_nested_fields false

      expect(subject.to_h['enable_nested_fields']).to be_falsey
    end

    it 'sets the enable_nested_fields value to true if no value was provided' do
      subject.enable_nested_fields

      expect(subject.to_h['enable_nested_fields']).to be_truthy
    end
  end
end
