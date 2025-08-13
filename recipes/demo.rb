# The Docker demo has no systemd. Its entrypoint runs the Chef-installed binary.
observability_node_exporter 'demo' do
  listen_address '0.0.0.0:9100'
  manage_service false
end
observability_prometheus_scrape 'demo' do
  path '/demo/prometheus/targets.json'
  targets ['exporter:9100']
  labels('environment' => 'demo', 'team' => 'platform')
end
observability_grafana_dashboard 'demo' do
  directory '/demo/grafana/dashboards'
  owner 'root'
  group 'root'
end
