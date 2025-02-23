include_recipe 'observability::node_exporter' if node['observability']['node_exporter']['enabled']
include_recipe 'observability::datadog' if node['observability']['datadog']['enabled']
include_recipe 'observability::splunk' if node['observability']['splunk']['enabled']
