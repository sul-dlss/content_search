[![Build Status](https://travis-ci.org/sul-dlss/content_search.svg?branch=master)](https://travis-ci.org/sul-dlss/content_search)
[![Coverage Status](https://coveralls.io/repos/github/sul-dlss/content_search/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/content_search?branch=master)
[![Code Climate](https://codeclimate.com/github/sul-dlss/content_search/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/content_search)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/content_search/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/content_search/coverage)
[![Dependency Status](https://gemnasium.com/sul-dlss/content_search.svg)](https://gemnasium.com/sul-dlss/content_search)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fcontent_search.svg)](https://badge.fury.io/gh/sul-dlss%2Fcontent_search)

# PURL

PURL service is a URL resolver that translates a reference to a digital object (in the form of a `druid`), into a full content representation of that object as available in public access environment


Please create a github release before deploying.

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
> druid = 'jg072yr3056' # e.g.
> IndexFullTextContentJob.perform_now(druid)
```
