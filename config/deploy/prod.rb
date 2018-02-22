server 'sul-contentsearch-prod-a.stanford.edu', user: 'contentsearch', roles: %w(web app)
server 'sul-contentsearch-prod-b.stanford.edu', user: 'contentsearch', roles: %w(web app)

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'
