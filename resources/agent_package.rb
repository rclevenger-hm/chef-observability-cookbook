unified_mode true

property :package_name, String, name_property: true
property :version, String, required: true
property :source_url, [String, nil], default: nil
property :checksum, [String, nil], default: nil

action :install do
  raise 'Only Debian and RHEL family packages are supported' unless %w(debian rhel).include?(node['platform_family'])
  Observability::Config.identifier!(new_resource.package_name, 'package name')
  Observability::Config.single_line!(new_resource.version, 'package version')

  if new_resource.source_url
    Observability::Config.https_url!(new_resource.source_url)
    Observability::Config.checksum!(new_resource.checksum)
    suffix = platform_family?('debian') ? 'deb' : 'rpm'
    artifact = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.package_name}-#{new_resource.checksum}.#{suffix}")
    remote_file artifact do
      source new_resource.source_url
      checksum new_resource.checksum
      mode '0600'
      sensitive true
    end
    if platform_family?('debian')
      dpkg_package new_resource.package_name do
        source artifact
        version new_resource.version
      end
    else
      rpm_package new_resource.package_name do
        source artifact
        version new_resource.version
      end
    end
  else
    package new_resource.package_name do
      version new_resource.version
      action :install
    end
  end
end
