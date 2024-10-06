# frozen_string_literal: true

RSpec.describe Typesensual::Search::Facet do
  subject do
    described_class.new('key', {
      'count' => 10,
      'value' => 'value',
      'highlighted' => 'highlighted'
    })
  end

  describe '#value' do
    it 'returns the value' do
      expect(subject.value).to eq('value')
    end
  end

  describe '#count' do
    it 'returns the count' do
      expect(subject.count).to eq(10)
    end
  end

  describe '#highlighted' do
    it 'returns the highlighted' do
      expect(subject.highlighted).to eq('highlighted')
    end
  end

  describe '#key' do
    it 'returns the key' do
      expect(subject.key).to eq('key')
    end
  end
end
