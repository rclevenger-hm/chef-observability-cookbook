require 'minitest/autorun'
require 'tmpdir'
require 'chef'
require 'chef/handler'
require_relative '../../files/default/chef_metrics_handler'

class MetricsHandlerTest < Minitest::Test
  Status = Struct.new(:success?, :elapsed_time, :updated_resources)

  def write_report(directory, success)
    handler = Observability::MetricsHandler.new(directory)
    handler.define_singleton_method(:run_status) { Status.new(success, 2.5, [:a, :b]) }
    handler.report
    File.read(File.join(directory, 'chef_client.prom'))
  end

  def test_success_and_failure_replace_metrics_atomically
    Dir.mktmpdir do |directory|
      assert_includes write_report(directory, true), 'chef_client_last_run_success 1'
      assert_includes write_report(directory, false), 'chef_client_last_run_success 0'
      assert_equal ['chef_client.prom'], Dir.children(directory)
      assert_equal 0644, File.stat(File.join(directory, 'chef_client.prom')).mode & 0777
    end
  end

  def test_duration_and_update_count_are_numeric
    Dir.mktmpdir do |directory|
      report = write_report(directory, true)
      assert_includes report, 'chef_client_run_duration_seconds 2.5'
      assert_includes report, 'chef_client_updated_resources 2'
      refute_includes report, 'api_key'
    end
  end
end
