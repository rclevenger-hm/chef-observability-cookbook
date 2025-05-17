require 'minitest/autorun'
require 'erb'

class SplunkTemplatesTest < Minitest::Test
  def setup
    @servers = ['b.test:9997', 'a.test:9997']
    @server_names = ['b.test', 'a.test']
    @ca_file = '/etc/receiver-ca.pem'
    @monitors = [{ 'path' => '/var/log/app.log', 'index' => 'application', 'sourcetype' => 'app:json' }]
  end

  def render(kind)
    ERB.new(File.read(File.expand_path("../../templates/default/splunk_#{kind}.conf.erb", __dir__)), trim_mode: '-').result(binding)
  end

  def test_tls_is_enabled_and_verifies_identity
    output = render('outputs')
    %w(useSSL sslVerifyServerCert sslVerifyServerName).each { |key| assert_includes output, "#{key} = true" }
    assert_includes output, 'server = a.test:9997,b.test:9997'
    assert_includes output, 'sslAltNameToCheck = a.test,b.test'
    refute_includes output, 'sslRootCAPath'
  end

  def test_trust_store_uses_server_configuration
    assert_includes render('server'), "[sslConfig]\nsslRootCAPath = /etc/receiver-ca.pem"
  end

  def test_input_mapping_preserves_index_and_sourcetype
    input = render('inputs')
    assert_includes input, '[monitor:///var/log/app.log]'
    assert_includes input, 'index = application'
    assert_includes input, 'sourcetype = app:json'
  end

  def test_empty_monitors_remove_managed_stanzas
    @monitors = []
    refute_includes render('inputs'), '[monitor://'
  end
end
