# frozen_string_literal: true

RSpec.describe Typesensual::Search do
  subject do
    described_class.new(
      collection: collection,
      query: 'foo',
      query_by: { name: 2, description: 1 }
    )
  end

  let(:collection) do
    Typesensual::Collection.new(
      name: 'test',
      fields: [
        { name: 'name', type: 'string' },
        { name: 'description', type: 'string' },
        { name: '.*', type: 'string*' }
      ]
    )
  end

  describe '#initialize' do
    context 'with a hash query_by' do
      it 'sets the query_by and query_by_weights' do
        search = described_class.new(
          collection: collection,
          query: '',
          query_by: { name: 2, description: 1 }
        )

        expect(search.query).to include(
          query_by: 'name,description',
          query_by_weights: '2,1'
        )
      end
    end

    context 'with a string query_by' do
      it 'sets the query_by' do
        search = described_class.new(
          collection: collection,
          query: '',
          query_by: 'name,description'
        )

        expect(search.query).to include(
          query_by: 'name,description'
        )
      end
    end

    context 'with a symbol query_by' do
      it 'sets the query_by' do
        search = described_class.new(
          collection: collection,
          query: '',
          query_by: :name
        )

        expect(search.query).to include(
          query_by: 'name'
        )
      end
    end

    context 'with an array query_by' do
      it 'sets the query_by' do
        search = described_class.new(
          collection: collection,
          query: '',
          query_by: %w[name description]
        )

        expect(search.query).to include(
          query_by: 'name,description'
        )
      end
    end
  end

  describe '#per' do
    it 'sets the per_page parameter' do
      expect(subject.per(10).query).to include(
        per_page: 10
      )
    end

    it 'returns a Search instance' do
      expect(subject.per(10)).to be_a(described_class)
    end
  end

  describe '#page' do
    it 'sets the page parameter' do
      expect(subject.page(3).query).to include(
        page: 3
      )
    end

    it 'returns a Search instance' do
      expect(subject.page(2)).to be_a(described_class)
    end
  end

  describe '#filter' do
    it 'returns a Search instance' do
      expect(subject.filter('foo:test')).to be_a(described_class)
    end

    context 'with a hash' do
      it 'adds key:value strings to the ANDed filter_by parameter' do
        search = subject.filter(foo: '=test', bar: '1..2')

        expect(search.query).to include(
          filter_by: 'foo:=test && bar:1..2'
        )
      end
    end

    context 'with an array' do
      it 'adds to the &&-separated filter_by parameter' do
        search = subject.filter(%w[test foo bar])

        expect(search.query).to include(
          filter_by: 'test && foo && bar'
        )
      end
    end

    context 'with a string' do
      it 'adds to the &&-separated filter_by parameter' do
        search = subject.filter('test')

        expect(search.query).to include(
          filter_by: 'test'
        )
      end
    end
  end

  describe '#sort' do
    it 'returns a Search instance' do
      expect(subject.sort('foo')).to be_a(described_class)
    end

    context 'with a hash' do
      it 'adds key:direction strings to the comma-separated sort_by parameter' do
        search = subject.sort(foo: :asc, text_match: :desc)

        expect(search.query).to include(
          sort_by: 'foo:asc,text_match:desc'
        )
      end
    end

    context 'with a string' do
      it 'adds to the comma-separated sort_by parameter' do
        search = subject.sort('test')

        expect(search.query).to include(
          sort_by: 'test'
        )
      end
    end
  end

  describe '#facet' do
    it 'returns a Search instance' do
      expect(subject.facet('foo')).to be_a(described_class)
    end

    context 'with a hash' do
      context 'with string values' do
        it 'adds the keys to the facet_by parameter' do
          search = subject.facet(foo: 'bar', baz: 'qux')

          expect(search.query).to include(
            facet_by: 'foo,baz'
          )
        end

        it 'adds the values to the facet_query parameter' do
          search = subject.facet(foo: 'bar', baz: 'qux')

          expect(search.query).to include(
            facet_query: 'foo:bar,baz:qux'
          )
        end

        it 'includes nil values in the facet_by parameter but not facet_query' do
          search = subject.facet(foo: 'bar', baz: nil)

          expect(search.query).to include(
            facet_by: 'foo,baz',
            facet_query: 'foo:bar'
          )
        end
      end

      context 'with hash values' do
        it 'adds the keys to the facet_by parameter' do
          search = subject.facet(foo: { query: 'bar' }, baz: { query: 'qux' })

          expect(search.query).to include(
            facet_by: 'foo,baz'
          )
        end

        it 'adds the query values to the facet_query parameter' do
          search = subject.facet(foo: { query: 'bar' }, baz: { query: 'qux' })

          expect(search.query).to include(
            facet_query: 'foo:bar,baz:qux'
          )
        end

        it 'adds the return_parent values to the facet_return_parent parameter' do
          search = subject.facet(foo: { return_parent: true })

          expect(search.query).to include(
            facet_return_parent: 'foo'
          )
        end

        it 'includes sort_by for default alphabetical sort' do
          search = subject.facet(foo: { sort: :asc })

          expect(search.query).to include(
            facet_by: 'foo(sort_by:_alpha:asc)'
          )
        end

        it 'includes sort_by for hash-sorted fields' do
          search = subject.facet(foo: { sort: { bar: :asc } })

          expect(search.query).to include(
            facet_by: 'foo(sort_by:bar:asc)'
          )
        end

        it 'includes sort_by for custom value' do
          search = subject.facet(foo: { sort: 'custom' })

          expect(search.query).to include(
            facet_by: 'foo(sort_by:custom)'
          )
        end

        it 'raises an ArgumentError when sort_by is not a string, symbol, or hash' do
          expect {
            subject.facet(foo: { sort: 1 })
          }.to raise_error(ArgumentError)
        end

        it 'includes ranges specified as Array objects' do
          search = subject.facet(foo: { ranges: { bad: [0, 2] } })

          expect(search.query).to include(
            facet_by: 'foo(bad:[0,2])'
          )
        end

        it 'includes ranges specified as Range objects' do
          search = subject.facet(foo: { ranges: { good: 8...10 } })

          expect(search.query).to include(
            facet_by: 'foo(good:[8,10])'
          )
        end

        it 'raises an ArgumentError when ranges are not a Hash' do
          expect {
            subject.facet(foo: { ranges: 'invalid' })
          }.to raise_error(ArgumentError)
        end

        it 'raises an ArgumentError when ranges are not a Range or Array' do
          expect {
            subject.facet(foo: { ranges: { bad: 1 } })
          }.to raise_error(ArgumentError)
        end

        it 'raises an ArgumentError when ranges are not exclusive' do
          expect {
            subject.facet(foo: { ranges: { invalid: 1..2 } })
          }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with an array' do
      it 'adds the values to the facet_by parameter' do
        search = subject.facet(%w[foo baz])

        expect(search.query).to include(
          facet_by: 'foo,baz'
        )
      end
    end

    context 'with a scalar string or symbol' do
      it 'adds it to the facet_by parameter' do
        search = subject.facet(:foo)

        expect(search.query).to include(
          facet_by: 'foo'
        )
      end
    end
  end

  describe '#include_fields' do
    it 'returns a Search instance' do
      expect(subject.include_fields('foo')).to be_a(described_class)
    end

    it 'adds the fields to the include_fields parameter' do
      search = subject.include_fields('foo', :bar)

      expect(search.query).to include(
        include_fields: 'foo,bar'
      )
    end
  end

  describe '#exclude_fields' do
    it 'returns a Search instance' do
      expect(subject.exclude_fields('foo')).to be_a(described_class)
    end

    it 'adds the fields to the exclude_fields parameter' do
      search = subject.exclude_fields('foo', :bar)

      expect(search.query).to include(
        exclude_fields: 'foo,bar'
      )
    end
  end

  describe '#group_by' do
    it 'returns a Search instance' do
      expect(subject.group_by('foo')).to be_a(described_class)
    end

    it 'adds to the group_by parameter' do
      search = subject.group_by('foo', :bar)

      expect(search.query).to include(
        group_by: 'foo,bar'
      )
    end
  end

  describe '#set' do
    it 'returns a Search instance' do
      expect(subject.set(foo: 'bar')).to be_a(described_class)
    end

    it 'adds the key:value pairs to the query' do
      search = subject.set(foo: 'bar', baz: 'qux')

      expect(search.query).to include(
        foo: 'bar',
        baz: 'qux'
      )
    end

    context 'with a nil value' do
      it 'removes the key from the query' do
        search = subject.set(foo: 'bar', baz: nil)

        expect(search.query).not_to include(:baz)
      end
    end
  end

  describe '#load' do
    before { collection.create! }

    it 'returns a Results instance' do
      expect(subject.load).to be_a(Typesensual::Search::Results)
    end
  end

  describe '.multi' do
    before { collection.create! }

    context 'with an array of queries' do
      it 'returns an array of Results instances' do
        results = described_class.multi(
          [
            subject,
            subject
          ]
        )

        expect(results).to include(
          an_instance_of(Typesensual::Search::Results),
          an_instance_of(Typesensual::Search::Results)
        )
      end
    end

    context 'with multiple queries' do
      it 'returns an array of Results instances' do
        results = described_class.multi(
          subject,
          subject
        )

        expect(results).to include(
          an_instance_of(Typesensual::Search::Results),
          an_instance_of(Typesensual::Search::Results)
        )
      end
    end

    context 'with a hash of queries' do
      it 'returns a hash of Results instances' do
        results = described_class.multi(
          query_a: subject,
          query_b: subject
        )

        expect(results).to include(
          query_a: an_instance_of(Typesensual::Search::Results),
          query_b: an_instance_of(Typesensual::Search::Results)
        )
      end
    end
  end
end
