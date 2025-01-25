require 'rake/testtask'
Rake::TestTask.new(:unit) do |t|
  t.libs << 'test'
  t.pattern = 'test/unit/*_test.rb'
end
task :spec do
  sh 'bundle exec rspec'
end
task default: [:unit, :spec]
