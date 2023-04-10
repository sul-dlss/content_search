# override the default behavior so we can override the root engine path to run all checks
OkComputer.mount_at = false

Rails.application.reloader.to_prepare do
  OkComputer::Registry.register "solr", OkComputer::HttpCheck.new(Search.client.uri.to_s.sub(/\/$/, '') + '/admin/ping')
end