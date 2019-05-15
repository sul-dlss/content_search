# index + delete SDR
every '*/15 * * * *' do
  runner 'HarvestPurlFetcherJob.perform_now'
end

# Build suggest index (enabling autocomplete)
every '0 3 * * *' do
  runner 'BuildSuggestJob.perform_now'
end
