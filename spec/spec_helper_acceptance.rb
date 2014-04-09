require 'puppet'
require 'beaker-rspec'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

hosts.each do |host|
  on host, "mkdir -p #{host['distmoduledir']}"
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

#  c.before(:each) do
#    Puppet::Util::Log.level = :warning
#    Puppet::Util::Log.newdestination(:console)
#  end

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module
    puppet_module_install(:source => proj_root, :module_name => 'puppet_stack')
    hosts.each do |host|
      on host, puppet('module','install','puppetlabs-apache'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-concat'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-postgresql'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','maestrodev-rvm'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
