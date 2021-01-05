# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.0'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails'

  gem 'simplecov'

  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'

  gem 'solr_wrapper'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rvm'
  gem 'dlss-capistrano'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'config'
gem 'honeybadger'
gem 'http'
gem 'newrelic_rpm', group: :production
gem 'nokogiri'
gem 'okcomputer'
gem 'parallel'
gem 'purl_fetcher-client', '~> 0.3'
gem 'redlock'
gem 'rsolr'
gem 'sidekiq', '~> 6.0'
gem 'whenever'
