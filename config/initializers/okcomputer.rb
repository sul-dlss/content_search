# override the default behavior so we can override the root engine path to run all checks
OkComputer.mount_at = false

OkComputer::Registry.register "solr", OkComputer::SolrCheck.new(Search.client.uri.to_s.sub(/\/$/, ''))
