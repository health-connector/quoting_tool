source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.8'

# Ruby 3.1+ compatibility - these standard libraries are now separate gems
# Temp fix for kube pod restarts
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.2.2.1'

# Use Puma as the app server
gem 'puma', '~> 6.6.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'aws-sdk'
gem 'rack-cors'
# Use to dry up responses
gem 'responders'

gem 'matrix'
# gem 'i18n', '~> 1.5'
gem 'rails-i18n', '7.0.9'

# MongoDB NoSQL database ORM
gem 'mongoid', '8.1.9'

# Settings, validation and dependency injection
gem 'dry-transaction', '~> 0.13.0'
gem 'jsonapi-serializer'
gem 'money-rails', '~> 1.13'
gem 'nokogiri', '~> 1.18.6'
gem 'nokogiri-happymapper', '~> 0.8.0', require: 'happymapper'
gem 'resource_registry', git: 'https://github.com/ideacrew/resource_registry.git', tag: 'v0.10.1'
gem 'roo', '~> 2.1'
gem 'virtus', '~> 1.0'

# bundler-audit upgrades
gem 'jmespath', '~> 1.6.1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'climate_control' #
  gem 'factory_bot_rails', '~> 4.11'
  gem 'pry-byebug', '~> 3.11.0'
  gem 'rspec-rails', '~> 7.1.1'
  gem 'yard', '~> 0.9.36', require: false
end

group :development do
  gem 'listen', '>= 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console',            '>= 3'

  gem 'rubocop',                require: false
  gem 'rubocop-git'
  gem 'rubocop-rspec'
end

group :test do
  gem 'database_cleaner-mongoid', '~> 2.0', '>= 2.0.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
