directory '/var/lib/node_exporter/textfile_collector' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end
directory '/etc/chef/handlers' do
  recursive true
  mode '0755'
end
cookbook_file '/etc/chef/handlers/observability_metrics.rb' do
  source 'chef_metrics_handler.rb'
  owner 'root'
  group 'root'
  mode '0644'
end
chef_handler 'Observability::MetricsHandler' do
  source '/etc/chef/handlers/observability_metrics.rb'
  supports report: true, exception: true
  action :enable
end
