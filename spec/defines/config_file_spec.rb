require 'spec_helper'

describe 'puppet_stack::smartproxy::config_file', :type => :define do
  context "with an illegal file name" do
    unsupported_examples = [nil, 'something.yml', 'bad.yml', 'puppetca1.yml', 'tftp2.yml']
    random_env_name = unsupported_examples[rand(unsupported_examples.length - 1)]
    let :title do
      random_env_name
    end
    let :params do
      {
        :content => { ':enabled' => true },
      }
    end
    it { expect { should compile }.to raise_error(/Invalid smart-proxy config filename/) }
  end

  context "on a RedHat system" do
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
         smartproxy     => true,
       }'
    end
    
    context "with content => set" do
      let :title do
        'puppet.yml'
      end
      let :params do
        {
          :content => { ':enabled' => true },
        }
      end
      it {
           should compile.with_all_deps
           should contain_class('puppet_stack::smartproxy')
           should contain_file('/usr/share/smartproxy/smart-proxy/config/settings.d/puppet.yml').with({
             'ensure' => 'file',
             'owner'  => 'smartproxy',
             'group'  => 'smartproxy',
             'mode'   => '0444',
           })
         }
    end
  end
end
