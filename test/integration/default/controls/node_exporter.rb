control 'node-exporter-runtime' do
  impact 1.0
  title 'The exporter runs without root and serves host metrics'
  describe service('node_exporter') do
    it { should be_enabled }
    it { should be_running }
  end
  describe user('node_exporter') do
    its('uid') { should_not eq 0 }
    its('shell') { should eq '/usr/sbin/nologin' }
  end
  describe port(9100) do
    it { should be_listening }
    its('addresses') { should include '127.0.0.1' }
  end
  describe http('http://127.0.0.1:9100/metrics') do
    its('status') { should eq 200 }
    its('body') { should match(/node_uname_info/) }
  end
  describe file('/etc/systemd/system/node_exporter.service') do
    its('content') { should match(/NoNewPrivileges=(true|yes)/) }
    its('content') { should include 'ProtectSystem=strict' }
  end
end
