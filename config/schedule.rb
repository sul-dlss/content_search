job_type :runner,  "cd :path && RAILS_LOG_LEVEL=warn :environment_variable=:environment bin/rails runner -e :environment ':task' :output"

# Garbage collect the index
every '15 * * * *' do
  runner 'GarbageCollectJob.perform_now'
end
