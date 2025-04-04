cfg = node['observability']['datadog']
secret = node.run_state.dig('observability', 'datadog_api_key') || ENV['OBSERVABILITY_DATADOG_API_KEY']
raise 'Provide Datadog API key through node.run_state or OBSERVABILITY_DATADOG_API_KEY' if secret.nil? || secret.empty?
observability_datadog_agent 'default' do
  api_key secret
  site cfg['site']
  tags cfg['tags']
  logs cfg['logs']
  manage_package cfg['manage_package']
  package_version cfg['package_version']
  package_url cfg['package_url']
  package_checksum cfg['package_checksum']
  manage_service cfg.fetch('manage_service', true)
  sensitive true
end
