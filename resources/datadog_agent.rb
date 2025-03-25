unified_mode true

property :api_key, String, required: true, sensitive: true
property :site, String, default: 'datadoghq.com'
property :tags, Array, default: []
property :logs, Array, default: []
property :manage_package, [true, false], default: false
property :package_version, [String, nil], default: nil
property :package_url, [String, nil], default: nil
property :package_checksum, [String, nil], default: nil
property :manage_service, [true, false], default: true

action :configure do
  config = Observability::Config.datadog(api_key: new_resource.api_key, site: new_resource.site,
                                        tags: new_resource.tags, logs: new_resource.logs)
  if new_resource.manage_package
    raise 'Datadog package_version is required when managing packages' unless new_resource.package_version
    observability_agent_package 'datadog-agent' do
      version new_resource.package_version
      source_url new_resource.package_url
      checksum new_resource.package_checksum
    end
  end
  directory '/etc/datadog-agent/conf.d/observability.d' do
    owner 'dd-agent'
    group 'dd-agent'
    mode '0750'
    recursive true
  end
  service 'datadog-agent' do
    action :nothing
  end
  file '/etc/datadog-agent/datadog.yaml' do
    content JSON.pretty_generate(config) + "\n"
    owner 'dd-agent'
    group 'dd-agent'
    mode '0600'
    sensitive true
    notifies :restart, 'service[datadog-agent]', :delayed if new_resource.manage_service
  end
  file '/etc/datadog-agent/conf.d/observability.d/conf.yaml' do
    content JSON.pretty_generate('logs' => new_resource.logs.map { |log| log.merge('type' => 'file') }) + "\n"
    owner 'dd-agent'
    group 'dd-agent'
    mode '0640'
    notifies :restart, 'service[datadog-agent]', :delayed if new_resource.manage_service
  end
  service 'datadog-agent' do
    action [:enable, :start]
    only_if { new_resource.manage_service }
  end
end
