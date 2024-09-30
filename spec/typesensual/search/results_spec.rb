# frozen_string_literal: true

RSpec.describe Typesensual::Search::Results do
  subject do
    described_class.new(
      'hits' => [
        {
          'highlights' => [],
          'document' => {
            'id' => '1',
            'name' => 'foobar'
          },
          'text_match' => 1
        }
      ],
      'grouped_hits' => [
        {}
      ],
      'request_params' => {
        'per_page' => 2
      },
      'found' => 10,
      'out_of' => 100,
      'page' => 1,
      'search_time_ms' => 21
    )
  end

  describe '#hits' do
    it 'returns an array of Hit objects' do
      expect(subject.hits).to all(be_a(Typesensual::Search::Hit))
    end
  end

  describe '#grouped_hits' do
    it 'returns an array of GroupedHit objects' do
      expect(subject.grouped_hits).to all(be_a(Typesensual::Search::GroupedHit))
    end
  end

  describe '#count' do
    it 'returns the total number of hits' do
      expect(subject.count).to eq(10)
    end
  end

  describe '#out_of' do
    it 'returns the total number of records searched' do
      expect(subject.out_of).to eq(100)
    end
  end

  describe '#current_page' do
    it 'returns the current page' do
      expect(subject.current_page).to eq(1)
    end
  end

  describe '#per_page' do
    it 'returns the number of records per page requested' do
      expect(subject.per_page).to eq(2)
    end
  end

  describe '#first_page?' do
    context 'when the current page is 1' do
      it 'returns true' do
        subject = described_class.new('page' => 1)

        expect(subject.first_page?).to be(true)
      end
    end

    context 'when the current page is not 1' do
      it 'returns false' do
        subject = described_class.new('page' => 2)
        expect(subject.first_page?).to be(false)
      end
    end
  end

  describe '#last_page?' do
    context 'when the current page is the last page' do
      it 'returns true' do
        subject = described_class.new(
          'page' => 10,
          'found' => 100,
          'request_params' => { 'per_page' => 10 }
        )

        expect(subject.last_page?).to be(true)
      end
    end

    context 'when the current page is not the last page' do
      it 'returns false' do
        subject = described_class.new(
          'page' => 9,
          'found' => 100,
          'request_params' => { 'per_page' => 10 },
        )

        expect(subject.last_page?).to be(false)
      end
    end
  end

  describe '#prev_page' do
    context 'when the current page is the first page' do
      it 'returns nil' do
        subject = described_class.new('page' => 1)
        expect(subject.prev_page).to be_nil
      end
    end

    context 'when the current page is not the first page' do
      it 'returns the previous page number' do
        subject = described_class.new('page' => 2)
        expect(subject.prev_page).to eq(1)
      end
    end
  end

  describe '#next_page' do
    context 'when the current page is the last page' do
      it 'returns nil' do
        subject = described_class.new(
          'page' => 10,
          'found' => 100,
          'request_params' => { 'per_page' => 10 }
        )

        expect(subject.next_page).to be_nil
      end
    end

    context 'when the current page is not the last page' do
      it 'returns the next page number' do
        subject = described_class.new(
          'page' => 9,
          'found' => 100,
          'request_params' => { 'per_page' => 10 }
        )

        expect(subject.next_page).to eq(10)
      end
    end
  end

  describe '#search_time_ms' do
    it 'returns the search time in milliseconds as returned from Typesense' do
      expect(subject.search_time_ms).to eq(21)
    end
  end
end
