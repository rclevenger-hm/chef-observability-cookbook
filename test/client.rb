require 'fileutils'
staging = '/tmp/observability-test-cookbooks'
FileUtils.mkdir_p(staging)
target = File.join(staging, 'observability')
File.symlink(File.expand_path('..', __dir__), target) unless File.exist?(target)
cookbook_path [File.expand_path('fixtures/cookbooks', __dir__), staging]
file_cache_path '/tmp/observability-chef-cache'
file_backup_path '/tmp/observability-chef-backup'
local_mode true
chef_zero.enabled true
