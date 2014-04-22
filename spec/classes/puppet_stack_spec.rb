require 'spec_helper'

describe 'puppet_stack', :type => 'class' do
  context "with ::puppetversion < 3.4.0" do
    # Thanks, dayglojesus
    unsupported_examples = ['0.25.5', '2.6.18', '2.7.26', '3.0', '3.1.1', '3.2.3', '3.3.1']
    random_puppet_vers = unsupported_examples[rand(unsupported_examples.length - 1)]
    let :facts do
      {
        :puppetversion => random_puppet_vers,
        :rubyversion   => '2.0.0',
      }
    end
    it { expect { should compile }.to raise_error(/module requires a Puppet version/) }
  end

  context "with ::rubyversion < 1.9.1" do
    unsupported_examples = ['1.8.6', '1.8.7']
    random_ruby_vers = unsupported_examples[rand(unsupported_examples.length - 1)]
    let :facts do
      {
        :puppetversion => '3.4.3',
        :rubyversion   => random_ruby_vers,
      }
    end
    it { expect { should compile }.to raise_error(/should not be using Ruby/) }
  end

  context "with an unsupported OS" do
    unsupported_examples = ['Debian', 'Windows', 'OpenSuSE', 'SuSE']
    random_os_family = unsupported_examples[rand(unsupported_examples.length - 1)]
    let :facts do
      {
        :osfamily               => random_os_family,
        :puppetversion          => '3.4.3',
        :rubyversion            => '2.0.0',
        :operatingsystemrelease => '6.5',
        :concat_basedir         => '/dne',
      }
    end
    let :params do
      {
        :ruby_vers => 'ruby-2.0.0-p451',
        :passenger_vers => '4.0.40',
      }
    end
    it { expect { should compile }.to raise_error(/does not support your OS/) }
  end

  context "on a RedHat system" do
    supported_puppet_versions = ['3.4.3', '3.5.1']
    random_puppet_vers = supported_puppet_versions[rand(supported_puppet_versions.length - 1)]
    let :facts do
      {
        :puppetversion          => random_puppet_vers,
        :rubyversion            => '2.0.0',
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
      }
    end

    context "with ruby_vers => not_valid" do
      unsupported_examples = [nil, 'ruby-1.9.3', '2.0.0-p451', 'ruby-2.0.0p451']
      random_ruby_vers = unsupported_examples[rand(unsupported_examples.length - 1)]
      let :params do
        {
          :ruby_vers => random_ruby_vers,
          :passenger_vers => '4.0.40',
        }
      end
      it { expect { should compile }.to raise_error(/valid Ruby version/) }
    end

    context "with passenger_vers => not_valid" do
      unsupported_examples = [nil, 'present']
      random_passenger_vers = unsupported_examples[rand(unsupported_examples.length - 1)]
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => random_passenger_vers,
        }
      end
      it { expect { should compile }.to raise_error(/(must be numerical)/) }
    end

    context "with only puppet => true" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :foreman        => false,
          :smartproxy     => false,
        }
      end
      it {
           should compile.with_all_deps
           should_not contain_class('puppet_stack::foreman')
           should_not contain_class('puppet_stack::smartproxy')
           should contain_class('puppet_stack::dependencies')
           should contain_class('puppet_stack::dependencies::generic')
           should contain_class('puppet_stack::dependencies::rhel')
           should contain_class('puppet_stack::puppet')
           should contain_class('puppet_stack::puppet::role::aio')
           should contain_class('puppet_stack::puppet::passenger')
           should contain_file('/etc/httpd/conf.d/puppet_master.conf').with({
             'ensure' => 'file',
             'owner'  => 'root',
             'group'  => 'root',
             'mode'   => '0444',
           })
           should contain_service('httpd').with_ensure('running')
         }
    end

    context "with puppet => true, puppet_role => catalog, ca_server => undef" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'catalog',
        }
      end
      it { expect { should compile }.to raise_error(/cannot be left undefined/) }
    end
    
    context "with puppet => true, puppet_role => catalog, conf_main => set with no ca_server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'catalog',
          :conf_main      => {
            'ssldir'        => '$vardir/ssl',
            'logdir'        => '/var/log/puppet',
            'privatekeydir' => '$ssldir/private_keys { group = service }',
            'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
            'server'        => $pm_server,
            'certname'      => $cert_name,
          }
        }
      end
      it { expect { should compile }.to raise_error(/conf_main hash shoud contain/) }
    end
    
    context "with puppet => true, puppet_role => catalog, conf_main => set with ca_server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'catalog',
          :conf_main      => {
            'ssldir'        => '$vardir/ssl',
            'logdir'        => '/var/log/puppet',
            'privatekeydir' => '$ssldir/private_keys { group = service }',
            'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
            'server'        => $pm_server,
            'certname'      => $cert_name,
            'ca_server'     => $ca_server,
          },
        }
      end
      it { should compile.with_all_deps }
    end
    
    context "with puppet => true, puppet_role => ca, pm_server => undef" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'ca',
        }
      end
      it { expect { should compile }.to raise_error(/cannot be left undefined/) }
    end
    
    context "with puppet => true, puppet_role => ca, pm_server => undef, conf_agent => set with no server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'ca',
          :conf_agent     => {
            'report'     => 'true',
            'listen'     => 'false',
            'pluginsync' => 'true',
            'certname'   => 'puppet.localdomain',
          },
        }
      end
      it { expect { should compile }.to raise_error(/cannot be left undefined/) }
    end
    
    context "with puppet => true, puppet_role => ca, conf_{main,agent} => set with no server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'ca',
          :conf_main      => {
            'ssldir'        => '$vardir/ssl',
            'logdir'        => '/var/log/puppet',
            'privatekeydir' => '$ssldir/private_keys { group = service }',
            'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
            'certname'      => $cert_name,
            'ca_server'     => $ca_server,
          },
          :conf_agent     => {
            'report'     => 'true',
            'listen'     => 'false',
            'pluginsync' => 'true',
            'certname'   => 'puppet.localdomain',
          },
        }
      end
      it { expect { should compile }.to raise_error(/conf_main or conf_agent hash should contain/) }
    end
    
    context "with puppet => true, puppet_role => ca, conf_agent => set with server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'ca',
          :conf_agent     => {
            'report'     => 'true',
            'listen'     => 'false',
            'pluginsync' => 'true',
            'certname'   => 'puppet.localdomain',
            'server'     => 'puppet.localdomain',
          },
        }
      end
      it { should compile.with_all_deps }
    end  
    
    context "with puppet => true, puppet_role => ca, conf_main => set with server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'ca',
          :conf_main      => {
            'ssldir'        => '$vardir/ssl',
            'logdir'        => '/var/log/puppet',
            'privatekeydir' => '$ssldir/private_keys { group = service }',
            'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
            'certname'      => $cert_name,
            'ca_server'     => $ca_server,
            'server'        => 'puppet.localdomain',
          },
        }
      end
      it { should compile.with_all_deps }
    end
    
    context "with puppet => true, puppet_role => ca, conf_main => set with no server key, conf_agent => set with server key" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => true,
          :puppet_role    => 'ca',
          :conf_main      => {
            'ssldir'        => '$vardir/ssl',
            'logdir'        => '/var/log/puppet',
            'privatekeydir' => '$ssldir/private_keys { group = service }',
            'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
            'certname'      => $cert_name,
            'ca_server'     => $ca_server,
          },
          :conf_agent     => {
            'report'     => 'true',
            'listen'     => 'false',
            'pluginsync' => 'true',
            'certname'   => 'puppet.localdomain',
            'server'     => 'puppet.localdomain',
          },
        }
      end
      it { should compile.with_all_deps }
    end

    context "with only foreman => true" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => false,
          :foreman        => true,
          :smartproxy     => false,
        }
      end
      it {
           should compile.with_all_deps
           should_not contain_class('puppet_stack::puppet')
           should_not contain_class('puppet_stack::smartproxy')
           should_not contain_class('puppet_stack::foreman::postgresql')
           should contain_class('puppet_stack::dependencies')
           should contain_class('puppet_stack::dependencies::generic')
           should contain_class('puppet_stack::dependencies::rhel')
           should contain_class('puppet_stack::foreman')
           should contain_class('puppet_stack::foreman::base')
           should contain_class('puppet_stack::foreman::rake')
           should contain_class('puppet_stack::foreman::passenger')
           should contain_file('/etc/httpd/conf.d/foreman.conf').with({
             'ensure' => 'file',
             'owner'  => 'root',
             'group'  => 'root',
             'mode'   => '0444',
           })
           should contain_service('httpd').with_ensure('running')
         }
    end

    context "with foreman => true, foreman_db_adapter => postgresql, foreman_db_password => undef" do
      let :params do
        {
          :ruby_vers          => 'ruby-2.0.0-p451',
          :passenger_vers     => '4.0.40',
          :puppet             => true,
          :foreman            => true,
          :foreman_db_adapter => 'postgresql',
        }
      end
      it do
        expect { should compile }.to raise_error(/cannot be left undefined/)
      end
    end

    context "with foreman => true, foreman_db_host => 'somehost.fqdn.com', foreman_db_password => set" do
      let :params do
        {
          :ruby_vers           => 'ruby-2.0.0-p451',
          :passenger_vers      => '4.0.40',
          :puppet              => true,
          :foreman             => true,
          :foreman_db_host     => 'somehost.fqdn.com',
          :foreman_db_password => 'set',
          :smartproxy          => true,
        }
      end
      it {
           should compile.with_all_deps
           should_not contain_class('puppet_stack::foreman::database::sqlite3')
           should_not contain_class('puppet_stack::foreman::database::postgresql')
           should contain_class('puppet_stack::dependencies')
           should contain_class('puppet_stack::dependencies::generic')
           should contain_class('puppet_stack::dependencies::rhel')
           should contain_class('puppet_stack::foreman')
           should contain_class('puppet_stack::foreman::base')
           should contain_class('puppet_stack::foreman::rake')
           should contain_class('puppet_stack::foreman::passenger')
           should contain_file('/etc/httpd/conf.d/foreman.conf').with({
             'ensure' => 'file',
             'owner'  => 'root',
             'group'  => 'root',
             'mode'   => '0444',
           })
           should contain_service('httpd').with_ensure('running')
         }
    end

    context "with only smartproxy => true" do
      let :params do
        {
          :ruby_vers      => 'ruby-2.0.0-p451',
          :passenger_vers => '4.0.40',
          :puppet         => false,
          :foreman        => false,
          :smartproxy     => true,
        }
      end
      it {
           should compile.with_all_deps
           should_not contain_class('puppet_stack::foreman')
           should_not contain_class('puppet_stack::puppet')
           should contain_class('puppet_stack::dependencies')
           should contain_class('puppet_stack::dependencies::generic')
           should contain_class('puppet_stack::dependencies::rhel')
           should contain_class('puppet_stack::smartproxy')
           should contain_class('puppet_stack::smartproxy::base')
           should contain_class('puppet_stack::smartproxy::passenger')
           should contain_file('/etc/httpd/conf.d/smartproxy.conf').with({
             'ensure' => 'file',
             'owner'  => 'root',
             'group'  => 'root',
             'mode'   => '0444',
           })
           should contain_service('httpd').with_ensure('running')
         }
    end
  end
end
