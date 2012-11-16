source 'https://rubygems.org'

gem 'rails', '3.2.6'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'therubyracer'


# chiliproject
gem "coderay", "~> 1.0.0"
gem "rubytree", "~> 0.5.2", :require => 'tree'
gem "rdoc", ">= 2.4.2"
gem "liquid", "~> 2.3.0"
gem "acts-as-taggable-on", "= 2.1.0"
gem 'awesome_nested_set'
gem 'open_id_authentication'
gem 'gravatarify', '~> 3.0.0'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'shoulda', '~> 2.10.3'
  # Shoulda doesn't work nice on 1.9.3 and seems to need test-unit explicitely…
  gem 'test-unit', :platforms => [:mri_19]
  gem 'edavis10-object_daddy', :require => 'object_daddy'
  gem 'mocha', '0.12.1'
  gem 'capybara'
end

group :ldap do
  gem "net-ldap", '~> 0.3.1'
end

group :openid do
  gem "ruby-openid", '~> 2.1.4', :require => 'openid'
end

group :rmagick do
  gem "rmagick", ">= 1.15.17"
end

platforms :mri, :mingw, :rbx do
  group :mysql2 do
    gem "mysql2", "~> 0.2.7"
  end

  group :postgres do
    gem "pg"
  end
end

platforms :mri_18, :mingw_18 do
  group :mysql do
    gem "mysql"
  end

  group :sqlite do
    gem "sqlite3-ruby", "< 1.3", :require => "sqlite3"
  end
end

platforms :mri_19, :mingw_19, :rbx do
  group :sqlite do
    gem "sqlite3"
  end
end

platforms :jruby do
  gem "jruby-openssl"

  group :mysql do
    gem "activerecord-jdbcmysql-adapter"
  end

  group :postgres do
    gem "activerecord-jdbcpostgresql-adapter"
  end

  group :sqlite do
    gem "activerecord-jdbcsqlite3-adapter"
  end
end

# Load a "local" Gemfile
gemfile_local = File.join(File.dirname(__FILE__), "Gemfile.local")
if File.readable?(gemfile_local)
  puts "Loading #{gemfile_local} ..." if $DEBUG
  instance_eval(File.read(gemfile_local))
end

# Load plugins' Gemfiles
["plugins", "chiliproject_plugins"].each do |plugin_path|
  Dir.glob File.expand_path("../vendor/#{plugin_path}/*/Gemfile", __FILE__) do |file|
    puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
    instance_eval File.read(file)
  end
end

gem 'jquery-rails'
