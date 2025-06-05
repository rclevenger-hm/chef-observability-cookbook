# Fixture users stand in for vendor-installed accounts. No vendor agent starts.
%w(dd-agent splunk).each do |account|
  group account
  user account do
    gid account
  end
end
directory '/opt/splunkforwarder/etc/system/local' do
  recursive true
end
observability_datadog_agent 'fixture' do
  api_key '0' * 32
  tags ['env:test', 'team:platform']
  logs [{ 'path' => '/var/log/app/*.log', 'service' => 'demo', 'source' => 'ruby' }]
  manage_service false
end
observability_splunk_forwarder 'fixture' do
  servers ['splunk.example.test:9997']
  server_names ['splunk.example.test']
  ca_file '/etc/ssl/certs/ca-certificates.crt'
  monitors [{ 'path' => '/var/log/app/*.log', 'index' => 'main', 'sourcetype' => 'app:json' }]
  manage_service false
end
