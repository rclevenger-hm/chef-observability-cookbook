# Run Chef's public application entrypoint when using the Ruby gem distribution.
$PROGRAM_NAME = File.expand_path($PROGRAM_NAME)
require 'chef'
require 'chef/application/client'
Chef::Application::Client.new.run
