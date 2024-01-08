[![Code Climate](https://codeclimate.com/github/sul-dlss/content_search/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/content_search)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/content_search/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/content_search/coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fcontent_search.svg)](https://badge.fury.io/gh/sul-dlss%2Fcontent_search)

# Content Search

Content Search provides a IIIF Content Search 0.9 API endpoint for "search-within" or "highlights-in-context" for digital object OCR.

## Requirements

1. Ruby (2.3.0 or greater)
2. [bundler](http://bundler.io/) gem

## Installation

Clone the repository

    $ git clone git@github.com:sul-dlss/content_search.git

Move into the app and install dependencies

    $ cd content_search
    $ bundle install

Start the development server

    $ rails s

## Configuring

Configuration is handled through the [RailsConfig](/railsconfig/config) `settings.yml` files.

#### Local Configuration

The defaults in `config/settings.yml` should work on a locally run installation.

## Testing

The test suite (with RuboCop style enforcement) will be run with the default rake task (also run on travis)

    $ bundle exec rake

The specs can be run without RuboCop style enforcement

    $ bundle exec rspec

The RuboCop style enforcement can be run without running the tests

    $ bundle exec rubocop

## Running Solr

In a new terminal window:

```bash
$ bundle exec solr_wrapper
```

## Indexing content

Content can be indexed from the Rails console:

```
> druid = 'bb034nj7139' # e.g.
> IndexFullTextContentJob.perform_now(druid)
```
You may need to commit this separately

```ruby
> Search.client.commit
```
