task :fixtures_env do
  ENV['FIXTURES'] = Dir["#{Rails.root}/test/fixtures/*.yml"].map { |f| File.basename f, '.yml' }.join ','
end
Rake::Task["db:fixtures:load"].enhance [:fixtures_env]