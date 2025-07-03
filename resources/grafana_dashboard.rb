unified_mode true

property :directory, String, default: '/var/lib/grafana/dashboards'
property :owner, String, default: 'grafana'
property :group, String, default: 'grafana'

action :create do
  Observability::Config.absolute_path!(new_resource.directory, 'dashboard directory')
  directory new_resource.directory do
    owner new_resource.owner
    group new_resource.group
    mode '0755'
    recursive true
  end
  cookbook_file "#{new_resource.directory}/chef-host-overview.json" do
    cookbook 'observability'
    source 'chef-host-overview.json'
    owner new_resource.owner
    group new_resource.group
    mode '0644'
  end
end
