# frozen_string_literal: true

RSpec.describe Typesensual::Config do
  subject { described_class.new }

  describe '#initialize' do
    context 'when provided a block' do
      it 'passes an instance into it' do
        expect { |b|
          described_class.new(&b)
        }.to yield_with_args(an_instance_of(described_class))
      end
    end

    context 'when not provided a block' do
      it 'creates an empty instance' do
        expect(described_class.new).to be_a(described_class)
      end
    end
  end

  describe '#env' do
    context 'when Rails is loaded' do
      before do
        fake_rails = double
        allow(fake_rails).to receive(:env).and_return('test')
        stub_const('Rails', fake_rails)
      end

      context 'with no explicit env provided' do
        it 'defaults env to Rails.env' do
          expect(subject.env).to eq('test')
        end
      end

      context 'with an explicit env provided' do
        before { subject.env = 'foo' }

        it 'uses the explicit env' do
          expect(subject.env).to eq('foo')
        end
      end
    end

    context 'when Rails is not loaded' do
      it 'does not load Rails' do
        expect(defined?(Rails)).to be_falsey
      end

      context 'with no explicit env provided' do
        it 'returns nil' do
          expect(subject.env).to be_nil
        end
      end

      context 'with an explicit env provided' do
        before { subject.env = 'foo' }

        it 'uses the explicit env' do
          expect(subject.env).to eq('foo')
        end
      end
    end
  end

  describe '#client' do
    context 'when an explicit client is provided' do
      let(:fake_client) { instance_double(Typesense::Client) }

      before { subject.client = fake_client }

      it 'provides the explicit client' do
        expect(subject.client).to eq(fake_client)
      end
    end

    context 'without an explicit client provided' do
      it 'creates a new client' do
        subject.nodes = [{ host: 'foo', port: 123, protocol: 'http' }]
        subject.api_key = 'xyz'

        expect(subject.client).to be_a(Typesense::Client)
      end

      it 'uses the configured nodes' do
        subject.nodes = [{ host: 'foo', port: 123, protocol: 'http' }]
        subject.api_key = 'xyz'

        expect(subject.client.configuration.nodes).to include(
          a_hash_including(
            host: 'foo',
            port: 123,
            protocol: 'http'
          )
        )
      end

      it 'uses the configured api_key' do
        subject.nodes = [{ host: 'foo', port: 123, protocol: 'http' }]
        subject.api_key = 'xyz'

        expect(subject.client.configuration.api_key).to eq('xyz')
      end
    end
  end

  describe '#nodes' do
    context 'with a TYPESENSUAL_NODES env var' do
      before do
        allow(ENV)
          .to receive(:[])
          .with('TYPESENSUAL_NODES')
          .and_return('http://foo:123,http://bar:456')
      end

      it 'parses the env var into a list of nodes' do
        config = described_class.new

        expect(config.nodes).to eq([
          { host: 'foo', port: 123, protocol: 'http' },
          { host: 'bar', port: 456, protocol: 'http' }
        ])
      end

      context 'when an explicit nodes list is provided' do
        it 'uses the explicit nodes list and ignores the env var' do
          config = described_class.new do |c|
            c.nodes = [{ host: 'baz', port: 789, protocol: 'http' }]
          end

          expect(config.nodes).to eq([{ host: 'baz', port: 789, protocol: 'http' }])
        end
      end
    end
  end

  describe '#api_key' do
    context 'with a TYPESENSUAL_API_KEY env var' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('TYPESENSUAL_API_KEY', nil)
          .and_return('abc')
      end

      it 'uses the env var' do
        config = described_class.new

        expect(config.api_key).to eq('abc')
      end

      context 'when an explicit api_key is provided' do
        it 'uses the explicit api_key and ignores the env var' do
          config = described_class.new do |c|
            c.api_key = 'xyz'
          end

          expect(config.api_key).to eq('xyz')
        end
      end
    end
  end
end
