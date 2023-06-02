# frozen_string_literal: true

RSpec.describe Typesensual::Collection do
  describe '.alias_name' do
    subject { Class.new(described_class) { alias_name 'test' } }

    it 'sets @alias_name on the class' do
      expect(subject.instance_variable_get(:@alias_name)).to eq('test')
    end
  end

  describe '.schema' do
    it 'sets @schema on the class' do
      collection = Class.new(described_class) { schema {} }

      expect(collection.instance_variable_get(:@schema)).to be_a(Typesensual::Schema)
    end

    it 'accepts a block to build the schema with Typesensual::Schema' do
      expect { |b|
        Class.new(described_class) do
          schema(&b)
        end
      }.to yield_with_args(an_instance_of(Typesensual::Schema))
    end
  end

  describe '.collection_name_for' do
    subject { Class.new(described_class) { alias_name 'test' } }

    context 'without an env configured' do
      before { Typesensual.config.env = nil }

      it 'returns the alias name and timestamp separated by an @' do
        time = Time.new(2020, 1, 1)

        expect(subject.collection_name_for(timestamp: time)).to eq('test@1577865600')
      end
    end

    context 'with an env configured' do
      before { allow(Typesensual.config).to receive(:env).and_return('staging') }

      it 'returns the alias name, env, and timestamp separated by : and @' do
        time = Time.new(2020, 1, 1)

        expect(subject.collection_name_for(timestamp: time)).to eq('test:staging@1577865600')
      end
    end
  end

  describe '#create!' do
    subject do
      Class.new(described_class) do
        alias_name 'test'

        schema do
          field :id, type: 'string'
        end
      end
    end

    it 'creates a collection' do
      expect {
        subject.create!
      }.to(change {
        Typesensual.client.collections.retrieve.count
      }.by(1))
    end

    it 'returns the collection name based on the current timestamp' do
      name = subject.create!
      expect(name).to match(/test@\d+/)
    end
  end

  describe '#update_alias!' do
    subject do
      Class.new(described_class) do
        alias_name 'test'

        schema do
          field :id, type: 'string'
        end
      end
    end

    it 'updates the alias to point to the provided collection name' do
      collection_name = subject.create!
      subject.update_alias!(collection_name)

      expect(Typesensual.client.aliases['test'].retrieve['collection_name']).to eq(collection_name)
    end
  end

  describe '#collections' do
    subject do
      Class.new(described_class) do
        alias_name 'test'

        schema do
          field :id, type: 'string'
        end
      end
    end

    let(:unrelated) do
      Class.new(described_class) do
        alias_name 'unrelated'

        schema do
          field :id, type: 'string'
        end
      end
    end

    before do
      subject.create!
      unrelated.create!
    end

    it 'does not return collections that do not match the alias name' do
      expect(subject.collections).not_to include(a_hash_including(
        name: 'unrelated'
      ))
    end

    it 'does return the collections that do match the alias name' do
      expect(subject.collections).to include(a_hash_including(
        name: 'test'
      ))
    end
  end
end
