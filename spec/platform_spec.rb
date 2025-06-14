require 'spec_helper'

describe 'platform profiles' do
  [['ubuntu', '22.04'], ['rocky', '9']].each do |platform, version|
    it "builds the configuration profile for #{platform}" do
      run = ChefSpec::SoloRunner.new(platform: platform, version: version,
                                    step_into: %w(observability_datadog_agent observability_splunk_forwarder))
                               .converge('observability_test::configuration')
      expect(run).to create_file('/etc/datadog-agent/datadog.yaml')
      expect(run).to create_template('/opt/splunkforwarder/etc/apps/chef_observability/local/outputs.conf')
      expect(run).to create_systemd_unit('SplunkForwarder.service')
    end
  end
end
