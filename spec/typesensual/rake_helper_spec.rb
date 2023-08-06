# frozen_string_literal: true

require 'paint'
Paint.mode = 0

require 'typesensual/rake_helper'

RSpec.describe Typesensual::RakeHelper do
  describe '.list' do
    let(:foo) do
      Class.new(Typesensual::Index) do
        def self.name
          'FooIndex'
        end

        schema do
          field :id, type: 'string'
        end
      end
    end

    before do
      allow(Typesensual::Index).to receive(:descendants).and_return([foo])
      foo.create!(version: 100)
      foo.reindex!([])
    end

    it 'has the correct output' do
      out = StringIO.new
      described_class.list(output: out)

      expect(out.string).to match(Regexp.new(<<~'OUTPUT'))
        ==> Foo Index
             Version\s+Created At\s+Documents\s+
             \d+\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\s+[0-9,]+\s+
          -> \d+\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\s+[0-9,]+\s+
      OUTPUT
    end
  end

  describe '.index' do
    let(:foo) { double }
    let(:foo_index) do
      Class.new(Typesensual::Index) do
        def self.name
          'FooIndex'
        end

        schema do
          field :id, type: 'string'
        end

        def index(ids)
          ids.each do |id|
            yield id: id.to_s
          end
        end
      end
    end

    before do
      allow(foo).to receive(:name).and_return('Foo')
      allow(foo).to receive(:ids).and_return([1, 2, 3])
      stub_const('FooIndex', foo_index)
      stub_const('Foo', foo)
    end

    it 'has the correct output' do
      out = StringIO.new
      described_class.index(
        index: 'FooIndex',
        model: 'Foo',
        output: out
      )

      expect(out.string).to match(
        /==> Indexing Foo into FooIndex \(Version \d+\)/
      )
    end

    it 'creates a new collection' do
      out = StringIO.new

      expect {
        described_class.index(
          index: 'FooIndex',
          model: 'Foo',
          output: out
        )
      }.to change { foo_index.collections.count }.by(1)
    end

    it 'inserts the documents in the new collection' do
      out = StringIO.new
      described_class.index(
        index: 'FooIndex',
        model: 'Foo',
        output: out
      )
      version = out.string.match(/\(Version (\d+)\)/)[1]
      coll = foo_index.collection_for(version: version)

      expect(coll.num_documents).to eq(3)
    end
  end

  describe '.update_alias' do
    let(:foo) do
      Class.new(Typesensual::Index) do
        def self.name
          'FooIndex'
        end

        schema do
          field :id, type: 'string'
        end
      end
    end

    before do
      stub_const('FooIndex', foo)
    end

    it 'has the correct output' do
      collection = foo.create!

      out = StringIO.new
      described_class.update_alias(
        index: 'FooIndex',
        version: collection.version,
        output: out
      )

      expect(out.string).to match(Regexp.new(<<~'OUTPUT'))
        ==> Alias for FooIndex
        Old: None \(N/A\)
        New: \d+ \(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\)
      OUTPUT
    end
  end

  describe '.drop_version' do
    let(:foo) do
      Class.new(Typesensual::Index) do
        def self.name
          'FooIndex'
        end

        schema do
          field :id, type: 'string'
        end
      end
    end

    before do
      stub_const('FooIndex', foo)
    end

    it 'has the correct output' do
      collection = foo.create!

      out = StringIO.new
      described_class.drop_version(
        index: 'FooIndex',
        version: collection.version,
        output: out
      )

      expect(out.string).to match(Regexp.new(<<~'OUTPUT'))
        ==> Dropped version \d+ of FooIndex
      OUTPUT
    end
  end
end
