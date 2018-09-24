# index + delete SDR
every '*/15 * * * *' do
  runner 'HarvestPurlFetcherJob.perform_now'
end
