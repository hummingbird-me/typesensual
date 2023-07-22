# frozen_string_literal: true

RSpec.describe Typesensual::Collection do
  describe '#initialize' do
    context 'with a collection name' do
      context 'which does not exist' do
        it 'raises an error' do
          expect {
            described_class.new('does_not_exist')
          }.to raise_error(Typesense::Error::ObjectNotFound)
        end
      end

      context 'which exists' do
        it 'does not raise an error' do
          Typesensual.client.collections.create(
            name: 'test',
            fields: [
              { name: '.*', type: 'string*' }
            ]
          )

          expect {
            described_class.new('test')
          }.not_to raise_error
        end
      end
    end

    context 'with a collection object' do
      it 'uses the provided data' do
        obj = described_class.new({ 'name' => 'test' })
        expect(obj.name).to eq('test')
      end
    end
  end

  describe '#created_at' do
    it 'returns the Time parsed from the created_at timestamp' do
      time = Time.now.floor
      subject = described_class.new('created_at' => time.to_i)

      expect(subject.created_at).to eq(time)
    end
  end

  describe '#default_sorting_field' do
    it 'returns the value for default_sorting_field' do
      subject = described_class.new('default_sorting_field' => 'foo')

      expect(subject.default_sorting_field).to eq('foo')
    end
  end

  describe '#enable_nested_fields?' do
    it 'returns the value for enable_nested_fields' do
      subject = described_class.new('enable_nested_fields' => true)

      expect(subject.enable_nested_fields?).to be(true)
    end
  end

  describe '#fields' do
    it 'returns a list of Field objects' do
      subject = described_class.new('fields' => [{ 'name' => 'foo' }])

      expect(subject.fields).to all(be_a(Typesensual::Field))
    end

    it 'wraps the provided data in Field objects' do
      subject = described_class.new('fields' => [{ 'name' => 'foo' }])

      expect(subject.fields.first.name).to eq('foo')
    end
  end

  describe '#name' do
    it 'returns the underlying collection name' do
      subject = described_class.new('name' => 'foo')

      expect(subject.name).to eq('foo')
    end
  end

  describe '#num_documents' do
    it 'returns the value for num_documents' do
      subject = described_class.new('num_documents' => 123)

      expect(subject.num_documents).to eq(123)
    end
  end

  describe '#symbols_to_index' do
    it 'returns the value for symbols_to_index' do
      subject = described_class.new('symbols_to_index' => %w[# !])

      expect(subject.symbols_to_index).to eq(%w[# !])
    end
  end

  describe '#token_separators' do
    it 'returns the value for token_separators' do
      subject = described_class.new('token_separators' => %w[- _])

      expect(subject.token_separators).to eq(%w[- _])
    end
  end

  describe '#index_name' do
    context 'with a fully formed collection name' do
      subject { described_class.new('name' => 'test:foo@1234') }

      it 'returns the index name parsed from the collection name' do
        expect(subject.index_name).to eq('test')
      end
    end

    context 'with a collection name without an environment' do
      subject { described_class.new('name' => 'test@1234') }

      it 'returns the index name parsed from the collection name' do
        expect(subject.index_name).to eq('test')
      end
    end

    context 'with a collection name without a version' do
      subject { described_class.new('name' => 'test:foo') }

      it 'returns the index name parsed from the collection name' do
        expect(subject.index_name).to eq('test')
      end
    end

    context 'with a collection name without environment or version' do
      subject { described_class.new('name' => 'test') }

      it 'returns the whole collection name' do
        expect(subject.index_name).to eq('test')
      end
    end

    context 'with a collection name having an invalid version' do
      subject { described_class.new('name' => 'test@bar') }

      it 'returns the whole collection name' do
        expect(subject.index_name).to eq('test@bar')
      end
    end
  end

  describe '#env' do
    context 'with a fully formed collection name' do
      subject { described_class.new('name' => 'test:foo@1234') }

      it 'returns the env parsed from the collection name' do
        expect(subject.env).to eq('foo')
      end
    end

    context 'with a collection name without an environment' do
      subject { described_class.new('name' => 'test@1234') }

      it 'returns nil' do
        expect(subject.env).to be_nil
      end
    end

    context 'with a collection name without a version' do
      subject { described_class.new('name' => 'test:foo') }

      it 'returns the env parsed from the collection name' do
        expect(subject.index_name).to eq('test')
      end
    end
  end

  describe '#version' do
    context 'with a fully formed collection name' do
      subject { described_class.new('name' => 'test:foo@1234') }

      it 'returns the version parsed from the collection name' do
        expect(subject.version).to eq('1234')
      end
    end

    context 'with a collection name without a version' do
      subject { described_class.new('name' => 'test:foo') }

      it 'returns nil' do
        expect(subject.version).to be_nil
      end
    end

    context 'with a collection name without an env' do
      subject { described_class.new('name' => 'test@1234') }

      it 'returns the version parsed from the collection name' do
        expect(subject.version).to eq('1234')
      end
    end
  end

  describe '#create!' do
    it 'creates itself in Typesense' do
      described_class.new(
        'name' => 'test',
        'fields' => [{ 'name' => '.*', 'type' => 'string*' }]
      ).create!

      expect(Typesensual.client.collections['test'].retrieve).to include(
        'name' => 'test'
      )
    end
  end

  describe '#delete!' do
    it 'deletes itself in Typesense' do
      subject = described_class.new(
        'name' => 'test',
        'fields' => [{ 'name' => '.*', 'type' => 'string*' }]
      )
      subject.create!

      expect {
        subject.delete!
      }.to(change { Typesensual.client.collections.retrieve.count }.by(-1))
    end
  end

  describe '.create!' do
    it 'creates a collection in Typesense' do
      described_class.create!(
        'name' => 'test',
        'fields' => [{ 'name' => '.*', 'type' => 'string*' }]
      )

      expect(Typesensual.client.collections['test'].retrieve).to include(
        'name' => 'test'
      )
    end

    it 'returns a Collection instance' do
      subject = described_class.create!(
        'name' => 'test',
        'fields' => [{ 'name' => '.*', 'type' => 'string*' }]
      )

      expect(subject).to be_a(described_class)
    end
  end

  describe '#insert_one!' do
    subject do
      described_class.create!(
        name: 'test',
        fields: [{ name: '.*', type: 'string*' }]
      )
    end

    it 'inserts a document into the collection' do
      expect {
        subject.insert_one!(id: '1', foo: 'bar')
      }.to(change { subject.reload.num_documents }.by(1))
    end
  end

  describe '#insert_many!' do
    subject do
      described_class.create!(
        name: 'test',
        fields: [{ name: '.*', type: 'string*' }]
      )
    end

    context 'when all documents are valid' do
      it 'inserts all the documents into the collection' do
        expect {
          subject.insert_many!([
            { id: '1', foo: 'bar' },
            { id: '2', foo: 'baz' }
          ])
        }.to(change { subject.reload.num_documents }.by(2))
      end

      it 'returns an empty array' do
        result = subject.insert_many!([
          { id: '1', foo: 'bar' },
          { id: '2', foo: 'baz' }
        ])
        expect(result).to eq([])
      end
    end

    context 'when some documents are invalid' do
      it 'inserts the valid documents into the collection' do
        expect {
          subject.insert_many!([
            { id: '1', foo: 'bar' },
            'invalid document'
          ])
        }.to(change { subject.reload.num_documents }.by(1))
      end

      it 'returns an array of errors' do
        results = subject.insert_many!([
          { id: '1', foo: 'bar' },
          'invalid document'
        ])

        expect(results).to include(a_hash_including('success' => false))
      end
    end
  end

  describe '#remove_one!' do
    it 'removes the document from the collection' do
      subject = described_class.create!(
        name: 'test',
        fields: [{ name: '.*', type: 'string*' }]
      )

      subject.insert_one!(id: '1', foo: 'bar')

      expect {
        subject.remove_one!('1')
      }.to change { subject.reload.num_documents }.by(-1)
    end
  end

  describe '#search' do
    it 'returns a Search instance' do
      subject = described_class.create!(
        name: 'test',
        fields: [{ name: '.*', type: 'string*' }]
      )

      expect(
        subject.search(query: 'foo', query_by: 'foo')
      ).to be_a(Typesensual::Search)
    end
  end
end
