require 'chef/handler'
require 'tempfile'

module Observability
  class MetricsHandler < Chef::Handler
    def initialize(directory = '/var/lib/node_exporter/textfile_collector')
      @directory = directory
    end

    def report
      # No node names, exception text, attributes or secrets are exported.
      lines = [
        '# HELP chef_client_last_run_timestamp_seconds End time of the most recent Chef run.',
        '# TYPE chef_client_last_run_timestamp_seconds gauge',
        "chef_client_last_run_timestamp_seconds #{Time.now.to_i}",
        '# HELP chef_client_last_run_success Whether the most recent Chef run succeeded.',
        '# TYPE chef_client_last_run_success gauge',
        "chef_client_last_run_success #{run_status.success? ? 1 : 0}",
        '# HELP chef_client_run_duration_seconds Duration of the most recent Chef run.',
        '# TYPE chef_client_run_duration_seconds gauge',
        "chef_client_run_duration_seconds #{run_status.elapsed_time.to_f}",
        '# HELP chef_client_updated_resources Resources changed by the most recent Chef run.',
        '# TYPE chef_client_updated_resources gauge',
        "chef_client_updated_resources #{run_status.updated_resources.length}",
      ]
      Tempfile.create(['chef_client', '.tmp'], @directory) do |file|
        file.chmod(0644)
        file.write(lines.join("\n") + "\n")
        file.flush
        file.fsync
        File.rename(file.path, File.join(@directory, 'chef_client.prom'))
      end
    rescue StandardError => e
      Chef::Log.warn("Unable to write Chef metrics (#{e.class})")
    end
  end
end
