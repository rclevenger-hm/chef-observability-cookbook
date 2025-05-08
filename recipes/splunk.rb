cfg = node['observability']['splunk']
observability_splunk_forwarder 'default' do
  servers cfg['servers']
  monitors cfg['monitors']
  ca_file cfg['ca_file']
  server_names cfg['server_names']
  manage_package cfg['manage_package']
  package_version cfg['package_version']
  package_url cfg['package_url']
  package_checksum cfg['package_checksum']
  accept_license cfg['accept_license']
  admin_password node.run_state.dig('observability', 'splunk_admin_password')
  manage_service cfg.fetch('manage_service', true)
  sensitive true
end
