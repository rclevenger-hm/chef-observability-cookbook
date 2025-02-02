require 'json'
require 'uri'

module Observability
  module Config
    module_function

    def single_line!(value, label)
      raise ArgumentError, "#{label} must be a nonempty single line" unless value.is_a?(String) && !value.empty? && !value.match?(/[\r\n\x00]/)
      value
    end

    def identifier!(value, label)
      raise ArgumentError, "invalid #{label}" unless value.is_a?(String) && value.match?(/\A[a-zA-Z0-9_.:-]+\z/)
      value
    end

    def absolute_path!(value, label)
      single_line!(value, label)
      raise ArgumentError, "#{label} must be an absolute path without traversal or stanza delimiters" unless value.start_with?('/') && !value.split('/').include?('..') && !value.match?(/[\[\]]/)
      value
    end

    def endpoint!(value)
      single_line!(value, 'endpoint')
      match = /\A(?:[a-zA-Z0-9_.-]+|\[[a-fA-F0-9:]+\]):([0-9]{1,5})\z/.match(value)
      raise ArgumentError, 'endpoint must be host:port (1-65535)' unless match && (1..65535).cover?(match[1].to_i)
      value
    end

    def checksum!(value)
      raise ArgumentError, 'a SHA-256 checksum is required' unless value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
      value
    end

    def https_url!(value)
      uri = URI.parse(value)
      raise ArgumentError, 'artifact URL must use HTTPS without credentials' unless uri.scheme == 'https' && uri.host && !uri.userinfo
      value
    rescue URI::InvalidURIError
      raise ArgumentError, 'invalid artifact URL'
    end

    def datadog(api_key:, site:, tags:, logs:)
      raise ArgumentError, 'Datadog API key must contain 32 hexadecimal characters' unless api_key.is_a?(String) && api_key.match?(/\A[0-9a-fA-F]{32}\z/)
      allowed = %w(datadoghq.com datadoghq.eu us3.datadoghq.com us5.datadoghq.com ap1.datadoghq.com ap2.datadoghq.com ddog-gov.com)
      raise ArgumentError, 'unsupported Datadog site' unless allowed.include?(site)
      tags.each { |tag| single_line!(tag, 'tag') }
      logs.each do |log|
        raise ArgumentError, 'logs require path, service and source' unless %w(path service source).all? { |key| log.key?(key) }
        absolute_path!(log['path'], 'log path')
        %w(service source).each { |key| single_line!(log[key], key) }
      end
      { 'api_key' => api_key, 'site' => site, 'tags' => tags.sort.uniq, 'logs_enabled' => !logs.empty?,
        'bind_host' => '127.0.0.1', 'apm_config' => { 'enabled' => false },
        'process_config' => { 'process_collection' => { 'enabled' => false } } }
    end

    def splunk(servers:, monitors:, ca_file:, server_names:)
      raise ArgumentError, 'at least one Splunk receiver is required' if servers.empty?
      servers.each { |server| endpoint!(server) }
      absolute_path!(ca_file, 'CA file')
      raise ArgumentError, 'at least one TLS receiver name is required' if server_names.empty?
      server_names.each { |name| identifier!(name, 'TLS receiver name') }
      paths = monitors.map do |monitor|
        absolute_path!(monitor.fetch('path'), 'monitor path')
        identifier!(monitor.fetch('index'), 'index')
        identifier!(monitor.fetch('sourcetype'), 'sourcetype')
        monitor['path']
      end
      raise ArgumentError, 'duplicate Splunk monitor paths' unless paths.uniq.length == paths.length
      true
    end

    def systemd_arg(value)
      single_line!(value, 'systemd argument')
      escaped = value.gsub(/[\\"%$]/) do |character|
        { '\\' => '\\\\', '"' => '\\"', '%' => '%%', '$' => '$$' }.fetch(character)
      end
      '"' + escaped + '"'
    end
  end
end
