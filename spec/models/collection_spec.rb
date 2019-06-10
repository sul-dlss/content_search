# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection do
  subject(:collection) { described_class.new }

  describe '.client' do
    it 'returns an RSolr client' do
      expect(described_class.client).to be_a_kind_of RSolr::Client
    end

    it 'uses base_url to configure the solr url' do
      expect(described_class.client.uri.to_s).to eq described_class.base_url
    end
  end

  describe '.collection_name' do
    it 'extracts the collection name from the solr_url' do
      expect(described_class.collection_name).to eq 'content_search'
    end
  end

  describe '.base_url' do
    it 'removes the solr from solr_url' do
      expect(described_class.base_url).to eq 'http://127.0.0.1:8983/'
    end
  end

  describe '#cluster_status' do
    it 'returns the cluster response from Solr' do
      cluster = {
        'collections' => {
        }
      }
      client = instance_double(RSolr::Client, send_and_receive: { 'cluster' => cluster })
      expect(described_class).to receive(:client).and_return(client)
      expect(collection.cluster_status).to eq 'cluster' => cluster
    end
  end

  describe '#shards' do
    let(:cluster) do
      {
        'collections' => {
          'content_search' => {
            'shards' => {
              'shard1': {
                'replicas': {
                  'node1': {},
                  'node2': {},
                  'node3': {}
                }
              }
            }
          }
        }
      }
    end

    it 'parses the cluster response from Solr' do
      client = instance_double(RSolr::Client, send_and_receive: { 'cluster' => cluster })
      expect(described_class).to receive(:client).and_return(client)
      expect(collection.shards).to eq 'shard1' => { 'replicas' => { 'node1' => {}, 'node2' => {}, 'node3' => {} } }
    end
  end

  describe '#replicas' do
    let(:cluster) do
      {
        'collections' => {
          'content_search' => {
            'shards' => {
              'shard1': {
                'replicas': {
                  'node1': {
                    'base_url': 'http://example1.com',
                    'core': 'foo'
                  },
                  'node2': {
                    'base_url': 'http://example2.com',
                    'core': 'bar'
                  }
                }
              }
            }
          }
        }
      }
    end

    it 'parses the cluster response from Solr' do
      client = instance_double(RSolr::Client, send_and_receive: { 'cluster' => cluster })
      expect(described_class).to receive(:client).and_return(client)
      expect(collection.replicas).to eq [
        'http://example1.com',
        'http://example2.com'
      ]
    end
  end

  describe '#build_suggest' do
    let(:cluster) do
      {
        'collections' => {
          'content_search' => {
            'shards' => {
              'shard1': {
                'replicas': {
                  'node1': {
                    'base_url': 'http://example1.com',
                    'core': 'foo'
                  }
                }
              }
            }
          }
        }
      }
    end

    it 'fires off jobs to build the suggest for each hosted core' do
      client = instance_double(RSolr::Client, send_and_receive: { 'cluster' => cluster })
      expect(described_class).to receive(:client).and_return(client)
      expect do
        collection.build_suggest
      end.to have_enqueued_job.with('http://example1.com', 'content_search')
    end
  end
end
