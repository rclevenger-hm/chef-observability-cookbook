unified_mode true

property :path, String, default: '/etc/prometheus/file_sd/chef_hosts.json'
property :targets, Array, required: true
property :labels, Hash, default: {}
property :owner, String, default: 'root'
property :group, String, default: 'root'

action :create do
  Observability::Config.absolute_path!(new_resource.path, 'file discovery path')
  new_resource.targets.each { |target| Observability::Config.endpoint!(target) }
  new_resource.labels.each do |key, value|
    raise 'invalid Prometheus label name' unless key.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/) && !key.start_with?('__')
    Observability::Config.single_line!(value, 'label value')
  end
  directory ::File.dirname(new_resource.path) do
    owner new_resource.owner
    group new_resource.group
    mode '0755'
    recursive true
  end
  file new_resource.path do
    content JSON.pretty_generate([{ 'targets' => new_resource.targets.sort.uniq, 'labels' => new_resource.labels.sort.to_h }]) + "\n"
    owner new_resource.owner
    group new_resource.group
    mode '0644'
  end
end
