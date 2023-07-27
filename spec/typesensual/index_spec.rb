# frozen_string_literal: true

RSpec.describe Typesensual::Index do
  describe '.index_name' do
    subject { Class.new(described_class) { index_name 'test' } }

    describe 'without a defined value' do
      subject do
        Class.new(described_class) do
          def self.name
            'ImplicitlyNamedIndex'
          end
        end
      end

      it 'returns the default index name' do
        expect(subject.index_name).to eq('implicitly_named')
      end
    end

    describe 'with a provided value to set' do
      subject { Class.new(described_class) }

      it 'sets @index_name on the class' do
        expect {
          subject.index_name('test_foo')
        }.to(change {
          subject.instance_variable_get(:@index_name)
        }.from(nil).to('test_foo'))
      end

      context 'when later called without an argument' do
        subject { Class.new(described_class) { index_name 'foo' } }

        it 'returns the set index_name' do
          expect(subject.index_name).to eq('foo')
        end
      end
    end
  end

  describe '.alias_name' do
    subject do
      Class.new(described_class) do
        index_name 'foo'

        def self.env
          'test'
        end
      end
    end

    it 'combines the index name and env with a colon in between' do
      expect(subject.alias_name).to eq('foo:test')
    end
  end

  describe '.collection_name_for' do
    subject { Class.new(described_class) { index_name 'test' } }

    context 'without an env configured' do
      before { Typesensual.config.env = nil }

      it 'returns the alias name and timestamp separated by an @' do
        time = Time.new(2020, 1, 1).strftime('%s')

        expect(subject.collection_name_for(version: time)).to eq("test@#{time}")
      end
    end

    context 'with an env configured' do
      before { allow(Typesensual.config).to receive(:env).and_return('staging') }

      it 'returns the alias name, env, and timestamp separated by : and @' do
        time = Time.new(2020, 1, 1).strftime('%s')

        expect(subject.collection_name_for(version: time)).to eq("test:staging@#{time}")
      end
    end
  end

  describe '.collections' do
    subject do
      Class.new(described_class) do
        index_name 'test'

        schema do
          field :id, type: 'string'
        end
      end
    end

    let(:unrelated) do
      Class.new(described_class) do
        index_name 'unrelated'

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
      expect(subject.collections).not_to include(an_object_having_attributes(
        index_name: 'unrelated'
      ))
    end

    it 'does return the collections that do match the alias name' do
      expect(subject.collections).to include(an_object_having_attributes(
        index_name: 'test'
      ))
    end
  end

  describe '.collection' do
    subject do
      Class.new(described_class) do
        index_name 'test'

        schema do
          field :id, type: 'string'
        end
      end
    end

    before { subject.update_alias!(subject.create!) }

    it 'returns a Collection' do
      expect(subject.collection).to be_a(Typesensual::Collection)
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

    context 'when called again' do
      it 'extends the existing schema' do
        index = Class.new(described_class) do
          schema do
            field :id, type: 'string'
          end
        end

        expect {
          index.schema do
            field :name, type: 'string'
          end
        }.to(change {
               index.schema.to_h['fields'].count
             }.from(1).to(2))
      end
    end

    context 'in a subclass' do
      let(:superclass) do
        Class.new(described_class) do
          schema do
            field :id, type: 'string'
          end
        end
      end

      it 'extends the superclass schema' do
        index = Class.new(superclass) do
          schema do
            field :name, type: 'string'
          end
        end

        expect(index.schema.to_h['fields']).to include({
          'name' => 'name',
          'type' => 'string'
        }, {
          'name' => 'id',
          'type' => 'string'
        })
      end

      it 'does not modify the superclass schema' do
        Class.new(superclass) do
          schema do
            field :name, type: 'string'
          end
        end

        expect(superclass.schema.to_h['fields']).not_to include({
          'name' => 'name',
          'type' => 'string'
        })
      end
    end
  end

  describe '.create!' do
    subject do
      Class.new(described_class) do
        index_name 'test'

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

    it 'returns the collection' do
      collection = subject.create!
      expect(collection).to be_a(Typesensual::Collection)
    end
  end

  describe '.update_alias!' do
    subject do
      Class.new(described_class) do
        index_name 'test'

        schema do
          field :id, type: 'string'
        end
      end
    end

    context 'with a Collection object' do
      it 'updates the alias to point to the provided collection' do
        collection = subject.create!
        subject.update_alias!(collection)

        expect(Typesensual.client.aliases['test'].retrieve['collection_name']).to eq(collection.name)
      end
    end

    context 'with a collection name' do
      it 'updates the alias to point to the provided collection name' do
        collection = subject.create!
        subject.update_alias!(collection.name)

        expect(Typesensual.client.aliases['test'].retrieve['collection_name']).to eq(collection.name)
      end
    end
  end

  describe '.reindex!' do
    subject do
      Class.new(described_class) do
        index_name 'test'

        schema do
          field '.*', type: 'string*'
        end
      end
    end

    context 'without an explicit collection' do
      it 'creates a new collection' do
        expect {
          subject.reindex!([])
        }.to(change {
          subject.collections.count
        }.by(1))
      end

      it 'changes the alias' do
        old = Typesensual::Collection.create!(
          name: 'foo',
          fields: [{ name: '.*', type: 'string*' }]
        )
        subject.update_alias!(old)

        expect {
          subject.reindex!([])
        }.to(change {
               Typesensual.client.aliases[subject.alias_name].retrieve['collection_name']
             }.from(old.name).to(an_instance_of(String)))
      end
    end

    context 'with an explicit collection' do
      it 'does not create a new collection' do
        coll = subject.create!

        expect {
          subject.reindex!([], collection: coll)
        }.not_to(change { subject.collections.count })
      end
    end

    it 'calls .index_many with the ids' do
      expect(subject).to receive(:index_many).with(
        %w[1 2 3],
        collection: an_instance_of(Typesensual::Collection)
      )

      subject.reindex!(%w[1 2 3])
    end
  end

  describe '.index_many' do
    it 'inserts the yielded rows from #index_many' do
      subject = Class.new(described_class) do
        index_name 'test'

        schema do
          field '.*', type: 'string*'
        end

        def index_many(ids)
          ids.each do |id|
            yield({ id: id })
          end
        end
      end

      coll = subject.create!

      expect {
        subject.index_many(%w[1 2 3], collection: coll)
      }.to change { coll.reload.num_documents }.by(3)
    end
  end

  describe '.index_one' do
    it 'inserts the yielded rows from #index_one' do
      subject = Class.new(described_class) do
        index_name 'test'

        schema do
          field '.*', type: 'string*'
        end

        def index_one(id)
          { id: id }
        end
      end

      coll = subject.create!

      expect {
        subject.index_one('1', collection: coll)
      }.to change { coll.reload.num_documents }.by(1)
    end
  end

  describe '#index_many' do
    it 'defaults to just calling #index_one over and over' do
      subject = Class.new(described_class) do
        index_name 'test'

        def index_one(id)
          { id: id }
        end
      end

      expect { |block|
        subject.new.index_many(%w[1 2 3], &block)
      }.to yield_successive_args(
        { id: '1' },
        { id: '2' },
        { id: '3' }
      )
    end
  end

  describe '#remove_one' do
    it 'removes the document from the collection' do
      subject = Class.new(described_class) do
        index_name 'test'

        schema do
          field '.*', type: 'string*'
        end
      end

      coll = subject.create!

      coll.insert_one!({ id: '1' })

      expect {
        subject.remove_one('1', collection: coll)
      }.to change { coll.reload.num_documents }.by(-1)
    end
  end

  describe '#ar_callbacks' do
    it 'returns a Typesensual::Callbacks instance' do
      subject = Class.new(described_class)

      expect(subject.ar_callbacks).to be_a(Typesensual::Callbacks)
    end
  end
end
