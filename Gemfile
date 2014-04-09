source 'https://rubygems.org'

if ENV.key?('PUPPET_VERSION')
  puppetversion = "= #{ENV['PUPPET_VERSION']}"
else
  puppetversion = '>= 3.4.0'
end

group :development, :test do
  gem 'rake'
  gem 'puppet-lint'
  gem 'rspec-puppet', :github => 'rodjek/rspec-puppet', :ref => '03e94422fb9bbdd950d5a0bec6ead5d76e06616b'
  gem 'beaker-rspec', :require => false
  gem 'puppetlabs_spec_helper'
  gem 'puppet', puppetversion
end
