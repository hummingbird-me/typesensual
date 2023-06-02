# frozen_string_literal: true

RSpec.describe Typesensual do
  it 'has a version number' do
    expect(Typesensual::VERSION).not_to be_nil
  end

  describe '#collections' do
    context 'with invalidly-named collections' do
      before do
        described_class.client.collections.create(
          name: 'test@foo',
          fields: [{ name: 'id', type: 'string' }]
        )
        described_class.client.collections.create(
          name: 'test@foo:bar',
          fields: [{ name: 'id', type: 'string' }]
        )
      end

      it 'does not choke' do
        expect(described_class.collections).to include(
          a_hash_including(name: 'test@foo', env: nil, timestamp: nil),
          a_hash_including(name: 'test@foo', env: 'bar', timestamp: nil)
        )
      end
    end

    context 'with no collections' do
      it 'returns an empty array' do
        expect(described_class.collections).to eq([])
      end
    end

    context 'with multiple collections' do
      before do
        5.times do |i|
          described_class.client.collections.create(
            name: "test_#{i}@1234567890",
            fields: [{ name: 'id', type: 'string' }]
          )
        end
      end

      it 'returns all collections' do
        expect(described_class.collections.count).to eq(5)
      end

      it 'returns a list of collection hashes' do
        expect(described_class.collections).to all(include(
          name: a_string_matching(/test_\d/),
          collection: an_instance_of(Typesense::Collection),
          timestamp: an_instance_of(Time),
          env: nil
        ))
      end
    end
  end
end
