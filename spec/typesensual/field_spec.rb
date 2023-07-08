# frozen_string_literal: true

RSpec.describe Typesensual::Field do
  describe '#initialize' do
    it 'accepts keyword args with symbol keys' do
      subject = described_class.new(name: 'foo')
      expect(subject.name).to eq('foo')
    end

    it 'accepts a hash with string keys' do
      subject = described_class.new('name' => 'foo')
      expect(subject.name).to eq('foo')
    end
  end

  describe '#facet?' do
    it 'returns the value of the facey key' do
      subject = described_class.new(facet: true)
      expect(subject.facet?).to be(true)
    end
  end

  describe '#index?' do
    it 'returns the value of the index key' do
      subject = described_class.new(index: true)
      expect(subject.index?).to be(true)
    end
  end

  describe '#infix?' do
    it 'returns the value of the infix key' do
      subject = described_class.new(infix: true)
      expect(subject.infix?).to be(true)
    end
  end

  describe '#locale' do
    context 'with an empty locale' do
      it 'returns nil' do
        subject = described_class.new(locale: '')
        expect(subject.locale).to be_nil
      end
    end

    context 'with a non-empty locale' do
      it 'returns the locale' do
        subject = described_class.new(locale: 'ja')
        expect(subject.locale).to eq('ja')
      end
    end
  end

  describe '#name' do
    context 'with a regex name' do
      it 'returns the source of the regex' do
        subject = described_class.new(name: /foo.*/)
        expect(subject.name).to eq('foo.*')
      end
    end

    context 'with a string name' do
      it 'returns the string' do
        subject = described_class.new(name: 'foo')
        expect(subject.name).to eq('foo')
      end
    end

    context 'with a symbol name' do
      it 'returns the symbol as a string' do
        subject = described_class.new(name: :foo)
        expect(subject.name).to eq('foo')
      end
    end
  end

  describe '#optional?' do
    it 'returns the value of the optional key' do
      subject = described_class.new(optional: true)
      expect(subject.optional?).to be(true)
    end
  end

  describe '#sort?' do
    it 'returns the value of the sort key' do
      subject = described_class.new(sort: true)
      expect(subject.sort?).to be(true)
    end
  end

  describe '#type' do
    it 'returns the value of the type key' do
      subject = described_class.new(type: 'string')
      expect(subject.type).to eq('string')
    end
  end

  describe '#to_h' do
    it 'overwrites the name key with the name method' do
      subject = described_class.new(name: :foo)
      expect(subject.to_h).to include(
        'name' => 'foo'
      )
    end

    it 'removes locale when it is empty' do
      subject = described_class.new(locale: '')
      expect(subject.to_h).not_to have_key('locale')
    end
  end
end
