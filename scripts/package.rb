require 'chef'
require 'chef/cookbook/metadata'
require 'json'
require 'tmpdir'
require 'fileutils'

root = File.expand_path('..', __dir__)
metadata = Chef::Cookbook::Metadata.new
metadata.from_file(File.join(root, 'metadata.rb'))
raise 'Invalid cookbook metadata' unless metadata.valid?
output = File.join(root, 'tmp', "observability-#{metadata.version}.tar.gz")
FileUtils.mkdir_p(File.dirname(output))
Dir.mktmpdir('observability-package') do |directory|
  cookbook = File.join(directory, 'observability')
  FileUtils.mkdir_p(cookbook)
  %w(attributes files libraries recipes resources templates metadata.rb README.md LICENSE).each do |entry|
    FileUtils.cp_r(File.join(root, entry), cookbook)
  end
  File.write(File.join(cookbook, 'metadata.json'), JSON.pretty_generate(metadata.to_hash) + "\n")
  raise 'Packaging failed' unless system('tar', '-czf', output, '-C', directory, 'observability')
end
puts output
