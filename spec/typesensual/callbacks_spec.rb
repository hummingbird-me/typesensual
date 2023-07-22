# frozen_string_literal: true

RSpec.describe Typesensual::Callbacks do
  describe '#after_create_commit' do
    it 'calls index.index_one with the record' do
      index = class_spy(Typesensual::Index)

      subject = described_class.new(index)
      record = double(id: 1)
      subject.after_create_commit(record)
      expect(index).to have_received(:index_one).with(1)
    end
  end

  describe '#after_update_commit' do
    context 'when should_update returns false' do
      it 'does not call index.index_one with the record' do
        index = class_spy(Typesensual::Index)
        subject = described_class.new(index, should_update: ->(_record) { false })
        record = double(id: 1)
        subject.after_update_commit(record)
        expect(index).not_to have_received(:index_one)
      end
    end

    context 'when should_update returns true' do
      it 'calls index.index_one with the record' do
        index = class_spy(Typesensual::Index)

        subject = described_class.new(index)
        record = double(id: 1)
        subject.after_update_commit(record)
        expect(index).to have_received(:index_one).with(1)
      end
    end
  end

  describe '#after_destroy_commit' do
    it 'calls index.delete_one with the record' do
      index = class_spy(Typesensual::Index)

      subject = described_class.new(index)
      record = double(id: 1)
      subject.after_destroy_commit(record)
      expect(index).to have_received(:remove_one).with(1)
    end
  end
end
