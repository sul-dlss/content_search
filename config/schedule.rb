job_type :runner,  "cd :path && :environment_variable=:environment bin/rails runner -e :environment ':task' :output"

# index + delete SDR
every '*/15 * * * *' do
  runner 'HarvestPurlFetcherJob.perform_now'
end

# Garbage collect the index
every '15 * * * *' do
  runner 'GarbageCollectJob.perform_now'
end
