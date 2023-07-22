# frozen_string_literal: true

RSpec.describe Typesensual::Search::Hit do
  subject do
    described_class.new(
      'highlights' => [{
        'field' => 'name',
        'matched_tokens' => ['foo'],
        'snippet' => '<mark>foo</mark>bar'
      }],
      'document' => {
        'id' => '1',
        'name' => 'foobar'
      },
      'text_match' => 69_420
    )
  end

  describe '#highlights' do
    it 'returns the raw highlights array' do
      expect(subject.highlights).to include(
        'field' => 'name',
        'matched_tokens' => ['foo'],
        'snippet' => '<mark>foo</mark>bar'
      )
    end
  end

  describe '#document' do
    it 'returns the raw document hash' do
      expect(subject.document).to include(
        'id' => '1',
        'name' => 'foobar'
      )
    end
  end

  describe '#score' do
    it 'returns the text match score' do
      expect(subject.score).to eq(69_420)
    end
  end
end
