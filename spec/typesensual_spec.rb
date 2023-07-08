# frozen_string_literal: true

RSpec.describe Typesensual do
  it 'has a version number' do
    expect(Typesensual::VERSION).not_to be_nil
  end

  describe '#collections' do
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

      it 'returns a list of Collections' do
        expect(described_class.collections).to all(be_a(Typesensual::Collection))
      end
    end
  end
end
