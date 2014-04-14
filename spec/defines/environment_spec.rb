require 'spec_helper'

describe 'puppet_stack::puppet::environment', :type => :define do
  let :facts do
    {
      :puppetversion          => '3.4.3',
      :rubyversion            => '2.0.0',
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '6',
      :concat_basedir         => '/dne',
    }
  end
  let :pre_condition do
    'class { \'puppet_stack\':
       ruby_vers      => \'ruby-2.0.0-p451\',
       passenger_vers => \'4.0.40\',
       foreman        => false,
       smartproxy     => false,
     }'
  end
  
  context "with an illegal environment name" do
    unsupported_examples = [nil, 'main', 'master', 'agent', 'user', '*magic']
    random_env_name = unsupported_examples[rand(unsupported_examples.length - 1)]
    let :title do
      random_env_name
    end
    let :params do
      {
        :ensure => 'present',
      }
    end
    it { expect { should compile }.to raise_error(/illegal environment name/) }
  end
  
  context "with an invalid ensure value" do
    unsupported_examples = [nil, 'file', 'directory']
    random_ensure_value = unsupported_examples[rand(unsupported_examples.length - 1)]
    let :title do
      'production'
    end
    let :params do
      {
        :ensure => random_ensure_value,
      }
    end
    it { expect { should compile }.to raise_error(/one of the following values: present, absent/) }
  end
  
  context "on any supported system" do
    let :title do
      'production'
    end
    let :params do
      {
        :ensure => 'present',
      }
    end
    it {
         should compile.with_all_deps
         should contain_class('puppet_stack::puppet')
         should contain_file('/etc/puppet').with({
           'ensure' => 'directory',
           'owner'  => 'root',
           'group'  => 'root',
           'mode'   => '0755',
         })
         should contain_file('/etc/puppet/environments').with({
           'ensure' => 'directory',
           'owner'  => 'root',
           'group'  => 'puppet',
           'mode'   => '0755',
         })
         should contain_file('/etc/puppet/environments/production').with({
           'ensure' => 'directory',
           'owner'  => 'root',
           'group'  => 'puppet',
           'mode'   => '0755',
         })
         should contain_file('/etc/puppet/environments/production/modules').with({
           'ensure' => 'directory',
           'owner'  => 'root',
           'group'  => 'puppet',
           'mode'   => '0755',
         })
         should contain_file("/etc/puppet/environments/production/manifests").with({
           'ensure' => 'directory',
           'owner'  => 'root',
           'group'  => 'puppet',
           'mode'   => '0755',
         })
       }
  end
end
