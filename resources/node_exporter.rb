unified_mode true

property :version, String, default: '1.10.2'
property :checksum, [String, nil], default: nil
property :download_base, String, default: 'https://github.com/prometheus/node_exporter/releases/download'
property :listen_address, String, default: '127.0.0.1:9100'
property :collectors, Array, default: []
property :disabled_collectors, Array, default: []
property :textfile_directory, String, default: '/var/lib/node_exporter/textfile_collector'
property :manage_service, [true, false], default: true

action :install do
  arch = { 'x86_64' => 'amd64', 'aarch64' => 'arm64' }[node['kernel']['machine']]
  raise 'node_exporter supports x86_64 and aarch64 only' unless arch
  raise 'version must be a stable semantic version' unless new_resource.version.match?(/\A\d+\.\d+\.\d+\z/)
  Observability::Config.endpoint!(new_resource.listen_address)
  Observability::Config.absolute_path!(new_resource.textfile_directory, 'textfile directory')
  (new_resource.collectors + new_resource.disabled_collectors).each { |c| Observability::Config.identifier!(c, 'collector') }
  raise 'a collector cannot be enabled and disabled' unless (new_resource.collectors & new_resource.disabled_collectors).empty?
  checksums = {
    'amd64' => 'c46e5b6f53948477ff3a19d97c58307394a29fe64a01905646f026ddc32cb65b',
    'arm64' => 'de69ec8341c8068b7c8e4cfe3eb85065d24d984a3b33007f575d307d13eb89a6',
  }
  checksum = new_resource.checksum || (checksums[arch] if new_resource.version == '1.10.2')
  Observability::Config.checksum!(checksum)
  basename = "node_exporter-#{new_resource.version}.linux-#{arch}"
  url = "#{new_resource.download_base}/v#{new_resource.version}/#{basename}.tar.gz"
  Observability::Config.https_url!(url)
  archive = ::File.join(Chef::Config[:file_cache_path], "#{basename}.tar.gz")
  destination = "/opt/node_exporter/#{new_resource.version}"

  group 'node_exporter' do
    system true
  end
  user 'node_exporter' do
    gid 'node_exporter'
    system true
    shell '/usr/sbin/nologin'
    home '/nonexistent'
    manage_home false
  end
  ['/opt/node_exporter', new_resource.textfile_directory].each do |path|
    directory path do
      recursive true
      owner 'root'
      group 'root'
      mode '0755'
    end
  end
  remote_file archive do
    source url
    checksum checksum
    owner 'root'
    mode '0644'
  end
  archive_file archive do
    destination destination
    overwrite true
    not_if { ::File.executable?("#{destination}/#{basename}/node_exporter") }
  end
  service 'node_exporter' do
    action :nothing
  end
  link '/usr/local/bin/node_exporter' do
    to "#{destination}/#{basename}/node_exporter"
    notifies :restart, 'service[node_exporter]', :delayed if new_resource.manage_service
  end
  flags = ["--web.listen-address=#{new_resource.listen_address}", "--collector.textfile.directory=#{new_resource.textfile_directory}"]
  flags.concat(new_resource.collectors.sort.uniq.map { |c| "--collector.#{c}" })
  flags.concat(new_resource.disabled_collectors.sort.uniq.map { |c| "--no-collector.#{c}" })
  systemd_unit 'node_exporter.service' do
    content(
      'Unit' => { 'Description' => 'Prometheus Node Exporter', 'After' => 'network-online.target', 'Wants' => 'network-online.target' },
      'Service' => {
        'Type' => 'simple', 'User' => 'node_exporter', 'Group' => 'node_exporter',
        'ExecStart' => '/usr/local/bin/node_exporter ' + flags.map { |flag| Observability::Config.systemd_arg(flag) }.join(' '),
        'Restart' => 'on-failure', 'RestartSec' => '5', 'NoNewPrivileges' => true,
        'ProtectSystem' => 'strict', 'ProtectHome' => true, 'PrivateTmp' => true,
        'ProtectKernelTunables' => true, 'ProtectControlGroups' => true,
        'RestrictSUIDSGID' => true, 'CapabilityBoundingSet' => '', 'UMask' => '0027',
      },
      'Install' => { 'WantedBy' => 'multi-user.target' }
    )
    verify new_resource.manage_service
    triggers_reload new_resource.manage_service
    action :create
    notifies :restart, 'service[node_exporter]', :delayed if new_resource.manage_service
  end
  service 'node_exporter' do
    action [:enable, :start]
    only_if { new_resource.manage_service }
  end
end
