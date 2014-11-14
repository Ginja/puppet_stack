require 'rubygems'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.before do
    # Thanks, maestrodev
    # avoid "Only root can execute commands as other users" errors
    Puppet.features.stubs(:root? => true)
  end
  # Turn rspec deprecation warnings into errors
  #c.raise_errors_for_deprecations!
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
end
