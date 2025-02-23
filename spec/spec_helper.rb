require 'chefspec'

RSpec.configure do |config|
  config.cookbook_path = [File.expand_path('../..', __dir__), File.expand_path('../test/fixtures/cookbooks', __dir__)]
  config.platform = 'ubuntu'
  config.version = '22.04'
end
