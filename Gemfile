source 'https://rubygems.org'

if ENV.key?('PUPPET_VERSION')
  puppetversion = "#{ENV['PUPPET_VERSION']}"
else
  puppetversion = '>= 3.4.0'
end

group :development, :test do
  gem 'rake'
  gem 'puppet-lint'
  gem 'rspec-puppet', :github => 'rodjek/rspec-puppet', :ref => '389f99ef666521fec1b4530fe69dc1ab84a060a8'
  gem 'beaker'
  gem 'beaker-rspec', :require => false
  gem 'puppetlabs_spec_helper'
  gem 'puppet', puppetversion
  gem 'pry'
end
