# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    raise 'Unable to load rubocop'
  end
end

# remove default rspec task
task(:default).clear
task default: %i[rubocop ci]

task ci: [:environment] do
  SolrWrapper.wrap(port: '8983') do |solr|
    FileUtils.cp File.join(__dir__, 'solr', 'lib', 'tokenizing-suggest-v1.0.1.jar'), File.join(solr.instance_dir, 'contrib')
    solr.with_collection(name: 'content_search',
                         dir: File.join(__dir__, 'solr', 'config')) do
      # run the tests
      Rake::Task['spec'].invoke
    end
  end
end
