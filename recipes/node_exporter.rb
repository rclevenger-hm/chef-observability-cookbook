cfg = node['observability']['node_exporter']
observability_node_exporter 'host' do
  version cfg['version']
  checksum cfg['checksum']
  listen_address cfg['listen_address']
  collectors cfg['collectors']
  disabled_collectors cfg['disabled_collectors']
  manage_service cfg.fetch('manage_service', true)
end
