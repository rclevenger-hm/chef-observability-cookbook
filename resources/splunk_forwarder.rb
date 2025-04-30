unified_mode true

property :servers, Array, required: true
property :monitors, Array, default: []
property :ca_file, String, required: true
property :server_names, Array, required: true
property :home, String, default: '/opt/splunkforwarder'
property :manage_package, [true, false], default: false
property :package_version, [String, nil], default: nil
property :package_url, [String, nil], default: nil
property :package_checksum, [String, nil], default: nil
property :accept_license, [true, false], default: false
property :admin_password, [String, nil], default: nil, sensitive: true
property :manage_service, [true, false], default: true

action :configure do
  Observability::Config.absolute_path!(new_resource.home, 'Splunk home')
  Observability::Config.splunk(servers: new_resource.servers, monitors: new_resource.monitors,
                              ca_file: new_resource.ca_file, server_names: new_resource.server_names)
  if new_resource.manage_package
    raise 'Splunk package_version and explicit accept_license are required' unless new_resource.package_version && new_resource.accept_license
    raise 'Managed Splunk packages use /opt/splunkforwarder' unless new_resource.home == '/opt/splunkforwarder'
    group 'splunk' do
      system true
    end
    user 'splunk' do
      gid 'splunk'
      home '/opt/splunkforwarder'
      shell '/usr/sbin/nologin'
      system true
      manage_home false
    end
    execute 'set-splunk-installation-owner' do
      command ['chown', '-R', 'splunk:splunk', '/opt/splunkforwarder']
      action :nothing
    end
    observability_agent_package 'splunkforwarder' do
      version new_resource.package_version
      source_url new_resource.package_url
      checksum new_resource.package_checksum
      notifies :run, 'execute[set-splunk-installation-owner]', :immediately
    end
  end
  app = "#{new_resource.home}/etc/apps/chef_observability/local"
  directory app do
    owner 'splunk'
    group 'splunk'
    mode '0750'
    recursive true
  end
  service 'SplunkForwarder' do
    action :nothing
  end
  %w(inputs outputs server).each do |kind|
    template "#{app}/#{kind}.conf" do
      source "splunk_#{kind}.conf.erb"
      cookbook 'observability'
      owner 'splunk'
      group 'splunk'
      mode '0640'
      variables(monitors: new_resource.monitors, servers: new_resource.servers,
                ca_file: new_resource.ca_file, server_names: new_resource.server_names)
      notifies :restart, 'service[SplunkForwarder]', :delayed if new_resource.manage_service
    end
  end
  if new_resource.admin_password
    Observability::Config.single_line!(new_resource.admin_password, 'Splunk admin password')
    raise 'Splunk admin password must have at least 12 characters' if new_resource.admin_password.length < 12
    file "#{new_resource.home}/etc/system/local/user-seed.conf" do
      content "[user_info]\nUSERNAME = admin\nPASSWORD = #{new_resource.admin_password}\n"
      owner 'splunk'
      group 'splunk'
      mode '0600'
      sensitive true
      not_if { ::File.exist?("#{new_resource.home}/etc/passwd") }
    end
  end
  ruby_block 'validate Splunk startup prerequisites' do
    block do
      raise 'Provision the Splunk receiver CA before starting the forwarder' unless ::File.file?(new_resource.ca_file)
      unless ::File.file?("#{new_resource.home}/etc/passwd") || new_resource.admin_password
        raise 'Provide a Splunk admin seed password for the first start'
      end
    end
    only_if { new_resource.manage_service }
  end
  systemd_unit 'SplunkForwarder.service' do
    content(
      'Unit' => { 'Description' => 'Splunk Universal Forwarder', 'After' => 'network-online.target', 'Wants' => 'network-online.target' },
      'Service' => {
        'Type' => 'forking', 'User' => 'splunk', 'Group' => 'splunk',
        'ExecStart' => "#{Observability::Config.systemd_arg(new_resource.home + '/bin/splunk')} start --no-prompt --answer-yes#{new_resource.accept_license ? ' --accept-license' : ''}",
        'ExecStop' => "#{Observability::Config.systemd_arg(new_resource.home + '/bin/splunk')} stop",
        'PIDFile' => "#{new_resource.home}/var/run/splunk/splunkd.pid", 'Restart' => 'on-failure',
        'TimeoutStartSec' => '120', 'TimeoutStopSec' => '120', 'LimitNOFILE' => '65536', 'UMask' => '0027',
      },
      'Install' => { 'WantedBy' => 'multi-user.target' }
    )
    verify new_resource.manage_service
    triggers_reload new_resource.manage_service
    action :create
    notifies :restart, 'service[SplunkForwarder]', :delayed if new_resource.manage_service
  end
  service 'SplunkForwarder' do
    action [:enable, :start]
    only_if { new_resource.manage_service }
  end
end
