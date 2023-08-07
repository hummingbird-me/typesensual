# frozen_string_literal: true

RSpec.describe Typesensual::Search::GroupedHit do
  subject do
    described_class.new(
      'group_key' => %w[420 69],
      'found' => 3,
      'hits' => [{}, {}, {}]
    )
  end

  describe '#hits' do
    it 'returns an array of Hit objects' do
      expect(subject.hits).to all(be_a(Typesensual::Search::Hit))
    end
  end

  describe '#group_ky' do
    it 'returns the group keys' do
      expect(subject.group_key).to eq(%w[420 69])
    end
  end

  describe '#count' do
    it 'returns the number of hits in the group' do
      expect(subject.count).to eq(3)
    end
  end
end
