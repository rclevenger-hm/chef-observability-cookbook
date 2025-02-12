require 'minitest/autorun'
require_relative '../../libraries/config'

class ConfigTest < Minitest::Test
  C = Observability::Config

  def test_endpoints_accept_dns_ipv4_and_bracketed_ipv6
    %w(localhost:9100 10.0.0.1:9997 [::1]:9100).each { |v| assert_equal v, C.endpoint!(v) }
  end

  def test_endpoints_reject_injection_and_invalid_ports
    ["host:9100\n--other", 'host:0', 'host:65536', '::1:9100', 'host', 'host:9997,other:9997'].each do |v|
      assert_raises(ArgumentError) { C.endpoint!(v) }
    end
  end

  def test_artifacts_require_https_without_embedded_credentials
    assert_equal 'https://example.test/agent.deb', C.https_url!('https://example.test/agent.deb')
    %w(http://example.test/a https://user:secret@example.test/a file:///tmp/a).each do |v|
      assert_raises(ArgumentError) { C.https_url!(v) }
    end
  end

  def test_checksums_must_be_complete
    assert_equal 'a' * 64, C.checksum!('a' * 64)
    [nil, '', 'a' * 63, 'z' * 64].each { |v| assert_raises(ArgumentError) { C.checksum!(v) } }
  end

  def test_paths_cannot_inject_splunk_stanzas
    ["/var/log/app\n[script://evil]", '/var/log/[evil]', '../etc', '/var/../etc'].each do |v|
      assert_raises(ArgumentError) { C.absolute_path!(v, 'path') }
    end
    assert_equal '/var/log/app/*.log', C.absolute_path!('/var/log/app/*.log', 'path')
  end

  def test_datadog_is_deterministic_and_disables_unused_collection
    config = C.datadog(api_key: 'a' * 32, site: 'datadoghq.com', tags: ['z:1', 'a:1', 'z:1'], logs: [])
    assert_equal ['a:1', 'z:1'], config['tags']
    assert_equal false, config['logs_enabled']
    assert_equal false, config.dig('apm_config', 'enabled')
    assert_equal '127.0.0.1', config['bind_host']
  end

  def test_datadog_rejects_bad_credentials_and_sites
    assert_raises(ArgumentError) { C.datadog(api_key: 'not-a-key', site: 'datadoghq.com', tags: [], logs: []) }
    assert_raises(ArgumentError) { C.datadog(api_key: 'a' * 32, site: 'attacker.example', tags: [], logs: []) }
  end

  def test_datadog_log_sources_require_complete_metadata
    assert_raises(ArgumentError) do
      C.datadog(api_key: 'a' * 32, site: 'datadoghq.com', tags: [], logs: [{ 'path' => '/var/log/a' }])
    end
  end

  def test_splunk_requires_receivers_and_tls_names
    assert_raises(ArgumentError) { C.splunk(servers: [], monitors: [], ca_file: '/etc/ca.pem', server_names: ['splunk.test']) }
    assert_raises(ArgumentError) { C.splunk(servers: ['splunk.test:9997'], monitors: [], ca_file: '/etc/ca.pem', server_names: []) }
  end

  def test_splunk_rejects_duplicate_monitors
    monitor = { 'path' => '/var/log/app.log', 'index' => 'main', 'sourcetype' => 'json' }
    assert_raises(ArgumentError) do
      C.splunk(servers: ['splunk.test:9997'], monitors: [monitor, monitor], ca_file: '/etc/ca.pem', server_names: ['splunk.test'])
    end
  end

  def test_systemd_escaping_does_not_expand_environment_or_specifiers
    assert_equal '"/some path/100%%/$$HOME"', C.systemd_arg('/some path/100%/$HOME')
    assert_raises(ArgumentError) { C.systemd_arg("bad\nargument") }
  end

  def test_systemd_escaping_preserves_quotes_and_backslashes
    value = '/path/with"quote\\backslash'
    expected = '"/path/with\\"quote\\\\backslash"'
    assert_equal expected, C.systemd_arg(value)
  end
end
