#puppet_stack

[![Build Status](https://travis-ci.org/Ginja/puppet_stack.svg?branch=master)](https://travis-ci.org/Ginja/puppet_stack)

##Table of Contents

1. [Overview - What does this module do?](#overview)
2. [Requirements - What does this module require?](#requirements)
3. [Usage - How do I use this module?](#usage)
  * [Sample Configurations - Resource examples](#sample configurations)
4. [Parameters - A definition of each module parameter](#parameters)
5. [Additional Notes - Things to be aware of](#additional notes)
6. [Development - What you need to know to contribute](#development)
  * [Versioning](#versioning)
  * [Branching](#branching)
  * [Testing](#testing)
  * [Vagrant](#vagrant)

##Overview

This module will help you install, and manage the following:

* A Puppet Master
* The Foreman
* smart-proxy

Where it differs from other similar modules is that it does so using git repos and gems instead of yum packages. What this offers is a greater degree of modularity, and control when performing upgrades.

This module also understands that a Puppet Master can have different roles:

1. An all-in-one (aio), which is a Puppet Master that serves out catalogs and is a Certificate Authority (CA).
2. A Puppet Catalog Master (catalog), which is a Puppet Master that only serves out client catalogs.
3. A Puppet CA server (ca), which is a Puppet Master that only manages client certificates.

##Requirements
Before you use this module, you'll require a machine with the following pre-installed:

* [System-wide RVM installation](https://rvm.io/)
```bash
curl -sSL https://get.rvm.io | sudo bash -s stable
```
* An RVM Ruby installation (> 1.8.{6,7}), which has been set as the system default:
```bash
rvm install ruby-2.0.0
rvm alias create default ruby-2.0.0
```
* Puppet Gem (3.4.0+) for that RVM Ruby installation:
```bash
gem install puppet
```

You can easily include all of this in a kickstart script, or do it yourself manually.

This module is quite dependent on other modules, which is not best practice, but it sure is convenient and extremely hard to avoid. The current module dependency list is:

* dependency 'puppetlabs/apache', '>=1.0.0'
* dependency 'puppetlabs/concat', '>= 1.0.0 <2.0.0'
* dependency 'puppetlabs/postgresql', '>= 3.1.0 <4.0.0'
* dependency 'maestrodev-rvm', '1.5.x'
* dependency 'puppetlabs/stdlib', '>=3.2.0 <5.0.0'

At this time, this module is only compatible with the RedHat OS family (i.e. RHEL, CentOS, Scientific Linux, etc..).

##Usage
This module has a lot of parameters to help you configure the finer details for each application. There are only two required parameters: 

* ruby_vers, the value of which should be what RVM Ruby version you've installed
* passenger_vers, the value of which should be the version of Passenger you want to install

This module will most likely be the the first thing you run on a Puppet Master. The following is an example of how you may want to do that:

```bash
# Get a root shell
sudo su -
# Check that you're using the Ruby version you expect
ruby --version
# Check that you're using the Puppet binary from the Puppet gem
which puppet
# Set SELINUX to permissive
setenforce 0
# Create some temporary holding directories
mkdir -p ~/puppet/modules ~/puppet/manifests
# Install this module, and any other modules you require
puppet module install ginja-puppet_stack --target-dir ~/puppet/modules
# Create a site.pp that contains the Puppet resources you want to apply
vi ~/puppet/manifests/site.pp
# Apply the manifest
puppet apply --verbose --modulepath ~/puppet/modules --manifestdir ~/puppet/manifests --detailed-exitcodes ~/puppet/manifests/site.pp
```

This module assumes SELINUX will be set to permissive. However, if you want to use it with SELINUX set to enforcing, you should follow the above instructions, and then do the following:

1. Install the management utilities for SELINUX
```bash
yum install policycoreutils-python
```
2. Start using your new stack (ex: access URLs, add a client, sign a certificate, etc...)
3. Generate a new SELINUX policy module
```bash
grep httpd /var/log/audit/audit.log | audit2allow -M puppet
```
4. Apply the policy module
```bash
semodule -i puppet.pp
```
5. Set SELINUX back to enforcing
```bash
setenforce 1
```

This should certainly help, but you may find that additional SELINUX adjustments are required. Use `chcon`, or try your hand at applying another policy module.

###Sample Configurations

An all-in-one Puppet Master, with the Foreman, and smart-proxy:

```puppet
# ruby_vers must be specified with a patch number
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
}
```

A Puppet CA server, with smart-proxy:

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  puppet_role    => 'ca',
  foreman        => false,
  smart_proxy    => true,
}
```

A Puppet Catalog Master, with the Foreman. 

When bringing up a Catalog Master, you must set the ca_server attribute to the FQDN of your Puppet CA server. In the example below, we assume puppet-ca.domain.here.com is our CA server, and that it contains an autosign entry for our Catalog Master. If you do not wish to use autosigning, set catalog_cert_autosign to false, configure the certificate for your Catalog Master manually after the first Puppet run, and then start a second Puppet run.

```puppet
class { 'puppet_stack':
  ruby_vers             => 'ruby-2.0.0-p451',
  passenger_vers        => '4.0.40',
  puppet_role           => 'catalog',
  ca_server             => 'puppet-ca.domain.here.com',
  catalog_cert_autosign => true,
  smart_proxy           => false,
}
```

Here's an advance example. Let's say we want to scale out our Puppet infrastructure:

* x1 Puppet CA server (puppet-ca.domain.com)
* x2 Puppet Catalog Masters (puppet-pm{1,2}.domain.com), possibly behind a load balancer

One of the Catalog Masters will include the Foreman, and the other will simply upload its client's facts & reports to it. The Puppet CA server will include smart-proxy, which the Foreman can use (has to be configured manually from within the application).

Order of execution is key here. The Puppet CA server will need to come up first if you're attempting to autosign your Puppet Catalog Masters' certificate. Otherwise if you try to bring up your Catalog Masters first, and catalog_cert_autosign is set to true, they will not come up properly. It's nothing you can't recover from (just bring up your CA server, ensure autosign is configured, and run Puppet again on each Catalog Master), but I think we all can agree that it's better when things just work the first time.

#####puppet-ca.domain.com

```puppet
# If you specify custom smartp_settings, do not forget to precede each setting key with a ':'
class { 'puppet_stack':
  ruby_vers        => 'ruby-2.0.0-p451',
  passenger_vers   => '4.0.40',
  puppet_role      => 'ca',
  autosign_entries => ['puppet-pm1.domain.com', 'puppet-pm2.domain.com'],
  foreman          => false,
  smartp_port      => '8443',
  smartp_settings  => {
    ':trusted_hosts'   => ['puppet-pm1.domain.com', 'puppet-pm2.domain.com'],
    ':daemon'          => true,
    ':port'            => '8443',
    ':use_rvmsudo'     => true, # Absolutely required, see additional notes
    ':tftp'            => false,
    ':dns'             => false,
    ':puppetca'        => true,
    ':ssldir'          => '/var/lib/puppet/ssl',
    ':puppetdir'       => '/etc/puppet',
    ':puppet'          => false,
    ':chefproxy'       => false,
    ':bmc'             => false,
    ':log_file'        => '/usr/share/smartproxy/smart-proxy/log/app.log', # The default location
    ':log_level'       => 'ERROR'
  }
}
```

#####puppet-pm1.domain.com

```puppet
class { 'puppet_stack':
  ruby_vers             => 'ruby-2.0.0-p451',
  passenger_vers        => '4.0.40',
  puppet_role           => 'catalog',
  ca_server             => 'puppet-ca.domain.com',
  catalog_cert_autosign => true,
  foreman               => true,
  smartproxy            => false,
}
```

#####puppet-pm2.domain.com

```puppet
class { 'puppet_stack':
  ruby_vers             => 'ruby-2.0.0-p451',
  passenger_vers        => '4.0.40',
  puppet_role           => 'catalog',
  ca_server             => 'puppet-ca.domain.com',
  catalog_cert_autosign => true,
  use_foreman_as_an_enc => true,
  foreman_url           => 'https://puppet-pm1.domain.com',
  foreman_upload_facts  => true,
  report_to_foreman     => true,
  foreman               => false,
  smartproxy            => false,
}
```

##Parameters

####`ruby_vers`
The RVM Ruby version you've installed on your system. You must append the patch version (ex: ruby-2.0.0-p451, ruby-1.9.3-p484).

####`passenger_vers`
The version of the passenger gem you want to install. Can not be set to present.

####`apache_user`
The Apache user for your machine (defaults to appropriate $::osfamily values).

####`http_dir`
The Apache http directory location (defaults to appropriate $::osfamily values).

####`rvm_prefix`
The location where RVM is installed (defaults to /usr/local/rvm).

####`bundler_vers`
The version of the bundler gem you want to install (defaults to present). Can also be set to a version number.

####`rack_vers`
The version of the rack gem you want to install (defaults to present). Can also be set to a version number.

####`global_passenger_options`
Global Passenger options that you want to apply globally to all web applications (defaults to an empty hash, which is none). Values specified will be put into the /etc/{http/apache2}/conf.d/passenger.conf file. Example:

```puppet
class { 'puppet_stack':
  ruby_vers => 'ruby-2.0.0-p451'
  ...
  global_passenger_options => {
    'PassengerDefaultUser'        => 'apache',
    'PassengerFriendlyErrorPages' => 'on',
    'PassengerMinInstances'       => '3'
  }
  ...
}
```

This would result in a conf.d/passenger.conf file that looks like this:

```
#####################
# MANAGED BY PUPPET #
#####################

LoadModule passenger_module /usr/local/rvm/gems/ruby-2.0.0-p451/gems/passenger-4.0.40/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /usr/local/rvm/gems/ruby-2.0.0-p451/gems/passenger-4.0.40
  PassengerDefaultRuby /usr/local/rvm/gems/ruby-2.0.0-p451/wrappers/ruby
</IfModule>

<IfModule mod_passenger.c>
  PassengerDefaultUser apache
  PassengerFriendlyErrorPages on
  PassengerMinInstances 3
</IfModule>
```

####`puppet`
If false (defaults to true), will prevent any type of Puppet Master from being configured.

####`puppet_role`
Specifies the type of Puppet Master to configure (defaults to aio). Valid options are aio (all-in-one), ca, and catalog.

####`cert_name`
The certificate name for the server (defaults to $::fqdn).

####`ca_server`
Specifies the CA server to use (defaults to undef). Only used if puppet_role is set to catalog, and if the default conf_main settings are used. If you specify your own conf_main settings, be sure to set the ca_server there.

####`autosign_entries`
An array of [Puppet autosign](http://docs.puppetlabs.com/puppet/latest/reference/ssl_autosign.html) entries to put into /etc/puppet/autosign.conf (defaults to an empty array).

####`site_pp_entries`
An array of entries to put into the default site manifest, /etc/puppet/manifests/site.pp (defaults to ['node default {}']). It's often common to put import statements in this file, but be aware that as of Puppet 3.5 import statements are [deprecated](http://docs.puppetlabs.com/puppet/latest/reference/lang_import.html).

####`catalog_cert_autosign`
If true (defaults to false), a catalog master will attempt to fetch its certificate from the specified CA server. For this to work an autosign entry for the Puppet Catalog Master needs to exist on the CA server (see the advanced example in the usage section).

####`conf_main`
A hash of configuration options to put into the [main] section of /etc/puppet/puppet.conf. If left unspecified, it defaults to two different values depending on what Puppet role you've chosen:

```ruby
# Default [main] settings for the catalog role
$conf_main_catalog = {
                       'ssldir'        => '$vardir/ssl',
                       'logdir'        => '/var/log/puppet',
                       'privatekeydir' => '$ssldir/private_keys { group = service }',
                       'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
                       'ca_server'     => $ca_server
                     }
# Defaults [main] settings for the aio, and ca role
$conf_main_aio_ca  = {
                       'ssldir'        => '$vardir/ssl',
                       'logdir'        => '/var/log/puppet',
                       'privatekeydir' => '$ssldir/private_keys { group = service }',
                       'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }'
                     }
```

####`conf_agent`
A hash of configuration options to put into the [agent] section of /etc/puppet/puppet.conf. If left unspecified, it defaults to two different values depending on what Puppet role you've chosen:

```ruby
# Defaults [agent] settings for the aio, and catalog role
$conf_agent_aio_catalog = {
                             'classfile'   => '$vardir/classes.txt',
                             'localconfig' => '$vardir/localconfig',
                             'report'      => true,
                             'listen'      => false,
                             'pluginsync'  => true,
                             'certname'    => $cert_name,
                             'server'      => $cert_name
                          }
# Defaults [agent] settings for the ca role
$conf_agent_ca          = {
                             'classfile'   => '$vardir/classes.txt',
                             'localconfig' => '$vardir/localconfig',
                             'report'      => true,
                             'listen'      => false,
                             'pluginsync'  => true,
                             'certname'    => $cert_name
                           }
```

####`conf_master`
A hash of configuration options to put into the [master] section of /etc/puppet/puppet.conf. If left unspecified, it defaults to several different values depending on what Puppet role you've chosen:

```ruby
# Defaults [master] settings for the aio role
$conf_master_aio     = {
                         'modulepath' => '$confdir/modules',
                         'ca'         => true,
                         'certname'   => $cert_name,
                         'autosign'   => '/etc/puppet/autosign.conf',
                         'reports'    => $log
                       }
# Defaults [master] settings for the catalog role
$conf_master_catalog = {
                         'modulepath' => '$confdir/modules',
                         'ca'         => false,
                         'certname'   => $cert_name,
                         'reports'    => $log
                       }
# Defaults [master] settings for the ca role
$conf_master_ca      = {
                         'ca'         => true,
                         'certname'   => $cert_name,
                         'autosign'   => '/etc/puppet/autosign.conf'
                       }
```

####`conf_envs`
An array that allow you to specify different environments in /etc/puppet/puppet.conf. If left unspecified, it defaults to:

```ruby
[
  [ 'production', { 'manifest' => '$confdir/manifests/site.pp' } ],
  [ 'development', { 'manifest' => '$confdir/manifests/site.pp' } ]
]
```
Acceptable values must follow the same syntax, [['string', {hash}]].

####`puppet_vhost_options`
The vhost options that you want to apply to Puppet (defaults to an empty hash, which means none). Values specified will be put into the /etc/{http/apache2}/conf.d/puppet_master.conf file. For an example of how to specify options, please refer to global_passenger_options.

####`puppet_ssl_cert`
The SSL certificate file that the Puppet Master will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`puppet_ssl_key`
The SSL key file that the Puppet Master will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`puppet_ssl_chain`
The SSL chain file that the Puppet Master will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`puppet_ssl_ca`
The SSL ca file that the Puppet Master will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`puppet_ssl_ca_revoc`
The SSL ca revocation file that the Puppet Master will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`puppet_passenger_app_root`
The Passenger application root for Puppet (defaults to /etc/puppet/rack).

####`puppet_passenger_doc_root`
The Passenger document root for Puppet (defaults to /etc/puppet/rack/public).

####`use_foreman_as_an_enc`
If true (default), will place /etc/puppet/node.rb and set the following options in the [master] section of /etc/puppet/puppet.conf:

```ini
external_nodes = /etc/puppet/node.rb
node_terminus = exec
```

If you want to use your own ENC script, set this to false and specify the proper options in your conf_master hash.

####`upload_facts_to_foreman`
If false (defaults to true), sets the appropriate value in /etc/puppet/node.rb that will prevent clients from uploading their Facter facts when they check-in. You will also need to the foreman_url if your Foreman is not on your Puppet Master.

####`foreman_url`
The URL of your Foreman instance (defaults to https://$::fqdn). This value is used in both puppet/node.rb, and reports/foreman.rb (see below). If you're using two Puppet Masters, set this value to the Puppet Master that is serving out the Foreman.

####`report_to_foreman`
If false (defaults to true), will prevent the placement of ${rvm_ruby_root}/gems/puppet-${::puppetversion}/lib/puppet/reports/foreman.rb, which will prevent Puppet from sending client reports to the Foreman. If you're not using the default value for conf_master, you will need to add 'foreman' as a value to report:

```ini
[master]
...
...
reports = log, foreman
```

####`foreman`
If false (defaults to true), will prevent Foreman from being configured.

####`foreman_repo`
The git repository from which to clone the Foreman. Defaults to the 1.4-stable branch of the official repo (https://github.com/theforeman/foreman.git -b 1.4-stable).

####`foreman_user`
The user that Passenger will run the Foreman under (defaults to foreman).

####`foreman_user_home`
The home of the foreman_user (defaults to /usr/share/foreman).

####`foreman_app_dir`
The application directory for the Foreman (defaults to ${foreman_user_home}/foreman). This should be the directory where foreman_repo clones to.

####`foreman_settings`
A hash of configuration options that will be put into the Foreman's config/settings.yaml file. Defaults settings are:

```ruby
$foreman_settings = {
                      ':unattended'            => false,
                      ':login'                 => true,
                      ':require_ssl'           => true,
                      ':locations_enabled'     => false,
                      ':organizations_enabled' => false,
                      ':support_jsonp'         => false,
                    }
```

As you can see, the Foreman is set just to be an ENC by default (:unattended => false). If you wish to use the Foreman to it's full potential specify your own hash, and set :unattended to true.

####`foreman_db_adapter`
The type of database adapter that the Foreman will use. Valid values are postgresql, and sqlite3 (default). If postgresql is specified, this module will use the puppetlabs-postgresql module to install and configure a database.

####`foreman_db_host`
The host where the Foreman's database resides (defaults to localhost). If this is not set to localhost, this module will assume the remote host and its database are ready to go, and will attempt to rake it.

####`foreman_db_name`
The name of the database the Foreman will use (defaults to foreman).

####`foreman_db_user`
The user the Foreman will use to access the database (defaults to foreman).

####`foreman_db_password`
The password for the foreman_db_user (defaults to undef). This must be set if foreman_db_adapater is set to anything other than sqlite3.

####`foreman_db_config`
An array of values that will be used to generate the Foreman's config/database.yml file. Defaults to the following values:

```puppet
# Shown for brevity & completeness
$test = [ 'test',
          { 'adapter'  => 'sqlite3',
            'database' => 'db/test.sqlite3',
            'pool'     => '5',
            'timeout'  => '5000' }
        ]
$dev  = [ 'development',
          { 'adapter'  => 'sqlite3',
            'database' => 'db/development.sqlite3',
            'pool'     => '5',
            'timeout'  => '5000' }
        ]
$sqlite3    = [
                $test,
                $dev,
                [ 'production',
                  { 'adapter'  => 'sqlite3',
                    'database' => 'db/production.sqlite3',
                    'pool'     => '5',
                    'timeout'  => '5000' }
                ]
              ]
$postgresql = [
                $test,
                $dev,
                [ 'production',
                  { 'adapter'  => 'postgresql',
                    'encoding' => 'unicode',
                    'host'     => $foreman_db_host,
                    'database' => $foreman_db_name,
                    'pool'     => '25',
                    'timeout'  => '5000',
                    'username' => $foreman_db_user,
                    'password' => $foreman_db_password }
                ]
              ]
```

If you were to specify your own values here, it should look like this:

```puppet
class { 'puppet_stack':
  ...
  foreman_db_config => [
    [ 'test',
      { 'adapter'  => 'sqlite3',
        'database' => 'db/test.sqlite3',
        'pool'     => '5',
        'timeout'  => '10000' }
    ],
    [ 'development',
      { 'adapter'  => 'sqlite3',
        'database' => 'db/development.sqlite3',
        'pool'     => '10',
        'timeout'  => '10000' }
    ],
    [ 'production',
      { 'adapter'  => 'postgresql',
        'encoding' => 'unicode',
        'host'     => 'localhost',
        'database' => 'foreman_production',
        'pool'     => '30',
        'timeout'  => '10000',
        'username' => 'myforemanuser',
        'password' => 'foryoureyesonly' }
    ]
  ],
}
```

####`foreman_vhost_options`
The vhost options that you want to apply to the Foreman (defaults to an empty hash, which means none). Values specified will be put into the /etc/{http/apache2}/conf.d/foreman.conf file. For an example of how to specify options, please refer to global_passenger_options.

####`foreman_vhost_server_name`
The ServerName value in the Foreman's vhost file.

####`foreman_ssl_cert`
The SSL certificate file that the Foreman will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`foreman_ssl_key`
The SSL key file that the Foreman will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`foreman_ssl_ca`
The SSL ca file that the Foreman will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`smartp_repo`
The git repository from which to clone smart-proxy. Defaults to the develop branch (see additional notes) of the official repo (https://github.com/theforeman/smart-proxy.git -b develop).

####`smartp_user`
The user that Passenger will run smart-proxy under (defaults to smartproxy).

####`smartp_user_home`
The home of the smartp_user (defaults to /usr/share/smartproxy).

####`smartp_port`
The port that the smart-proxy will listen on (defaults to 8443).

####`smartp_app_dir`
The application directory for smart-proxy (defaults to ${smartp_user_home}/smart-proxy). This should be the directory where smartp_repo clones to.

####`smartp_log_file`
The log file for the smart-proxy application (defaults to smart-proxy/log/app.log). If you change the value for this parameter you must ensure the directory where it resides in exists. Otherwise smart-proxy will fail to start.

####`smartp_settings`
A hash of configuration options that will be put into smart-proxy's config/settings.yml file. Defaults settings are:

```puppet
$smartp_settings = {
  ':ssl_certificate' => $smartp_ssl_cert,
  ':ssl_private_key' => $smartp_ssl_key,
  ':ssl_ca_file'     => $smartp_ssl_ca,
  ':trusted_hosts'   => [ $::fqdn ],
  ':sudo_command'    => "${rvm_prefix}/bin/rvmsudo",
  ':daemon'          => true,
  ':port'            => $smartp_port,
  ':tftp'            => false,
  ':dns'             => false,
  ':puppetca'        => $puppetca,
  ':ssldir'          => '/var/lib/puppet/ssl',
  ':puppetdir'       => '/etc/puppet',
  ':puppet'          => $puppet,
  ':chefproxy'       => false,
  ':bmc'             => false,
  ':log_file'        => $smartp_log_file,
  ':log_level'       => 'ERROR'
}
```
If you specify your own settings, be sure to prepend your keys with ':'.

####`smartp_vhost_options`
The vhost options that you want to apply to smart-proxy (defaults to an empty hash, which means none). Values specified will be put into the /etc/{http/apache2}/conf.d/smart-proxy.conf file. For an example of how to specify options, please refer to global_passenger_options.

####`smartp_vhost_server_name`
The ServerName value in smart-proxy's vhost file.

####`smartp_ssl_cert`
The SSL certificate file that smart-proxy will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`smartp_ssl_key`
The SSL key file that smart-proxy will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`smartp_ssl_ca`
The SSL ca file that smart-proxy will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.


##Additional Notes
* At this time, you must use the develop branch of smart-proxy in order for it to operate correctly. This will be the case until these two ([1](https://github.com/theforeman/smart-proxy/commit/04148e799c23d7b2024dfb812d04f803f80449da), [2](https://github.com/theforeman/smart-proxy/commit/3824d182ed364cbc844138e4d107c9336fd4c756)) commits have been merged into any of the release branches.

* There are seams in this module for the Apache and Postgresql dependencies that allow you to specify your own server configuration for both. For example, say you wanted the Apache module to not install the default modules and conf.d files. You could specify that like so in your node manifest:
```puppet
  # Ensure the resource is declared BEFORE puppet_stack
  class { 'apache':
    default_mods        => false,
    default_confd_files => false,
  }

  class { 'puppet_stack':
    ruby_verion => 'ruby-2.0.0-p451',
  }
```
* This module does not manage any type of firewall. You will need to open up the appropriate ports yourself. The ports, if left at the defaults, are: 443, 8140, and 8443.

* Some exec resources may take a long time to finish depending on your Internet connection. Therefore certain exec resources have had their timeout attribute increased to 30 minutes. Don't be worried if your first Puppet run seems to be stalled.

##Development

###Versioning
This module uses [Semantic Versioning](http://semver.org/).

###Branching
Please adhere to the branching guidelines set out by Vincent Driessen in this [post](http://nvie.com/posts/a-successful-git-branching-model/).

###Testing
This module uses [rspec-puppet](http://rspec-puppet.com), [beaker-rspec](https://github.com/puppetlabs/beaker-rspec), and [Beaker](https://github.com/puppetlabs/beaker) for testing.

To run the rspec-puppet tests:

```bash
cd puppet_stack
bundle install --path vendor

# Run rspec-puppet tests
# You may need to use sudo -E or rvmsudo as there are exec resources that run as another user
sudo -E bundle exec rake spec
```

To run the beaker tests:

1. Install [Vagrant](http://www.vagrantup.com/downloads.html) 1.5+
2. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 4.3.10+
3. `cd puppet_stack && bundle install --path vendor` if you haven't already
4. And finally:

```bash
# Run beaker tests
RS_DEBUG=yes bundle exec rspec spec/acceptance
```
For now, ignore the RVM warnings about $PATH not being set correctly.

###Vagrant
If you want to run this module through Vagrant (1.5+) manually:

```bash
mkdir -p ~/vagrant/puppet_stack && cd !$
vagrant init ginja/centos-6.5-x64-rvm-ruby2.0.0-puppet
mkdir modules manifests
touch manifests/site.pp
sudo puppet module install ginja-puppet_stack --target-dir ./modules
```

Edit the Vagrantfile like so:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ginja/centos-6.5-x64-rvm-ruby2.0.0-puppet"
  config.ssh.username = "vagrant"
  config.vm.hostname = "puppet-pm"

  # Uncomment, and modify the following if you want to use a bridge connection
  #config.vm.network "public_network", :bridge => 'en1: Wi-Fi (AirPort)', :mac => "080027468730"
  #config.vm.network "public_network", :bridge => 'en0: Ethernet', :mac => "080027468730"
  config.vm.network :private_network, ip: "192.168.1.82", :netmask => "255.255.255.0"

  config.vm.provider :virtualbox do |vb|
    # Custom VirtualBox settings
  end

  config.vm.provision :puppet do |puppet|
     puppet.module_path = "modules"
     puppet.manifests_path = "manifests"
     puppet.manifest_file  = "site.pp"
     puppet.options = "--verbose"
  end
end
```

Modify manifests/site.pp, and add the resource you want to test:

```puppet
class { 'puppet_stack':
  ruby_vers                => 'ruby-2.0.0-p451',
  passenger_vers           => '4.0.37',
  global_passenger_options => {
    'PassengerDefaultUser'        => 'apache',
    'PassengerFriendlyErrorPages' => 'on',
    'PassengerMinInstances'       => '2'
  },
  puppet_role              => 'ca',
  foreman                  => false,
  autosign_entries         => ['puppet-pm1.domain.com', 'puppet-pm2.domain.com'],
  smartp_settings          => {
    ':trusted_hosts'   => [ 'puppet-pm1.domain.com', 'puppet-pm2.domain.com' ],
    ':daemon'          => true,
    ':port'            => '8443',
    ':use_rvmsudo'     => true,
    ':tftp'            => false,
    ':dns'             => false,
    ':puppetca'        => true,
    ':ssldir'          => '/var/lib/puppet/ssl',
    ':puppetdir'       => '/etc/puppet',
    ':puppet'          => false,
    ':chefproxy'       => false,
    ':bmc'             => false,
    ':log_file'        => '/usr/share/smartproxy/smart-proxy/log/app.log',
    ':log_level'       => 'ERROR'
  }
}
```

Bring up the box, and watch the magic happen:

```bash
vagrant up
```

The [ginja/centos-6.5-x64-rvm-ruby2.0.0-puppet](https://vagrantcloud.com/ginja/centos-6.5-x64-rvm-ruby2.0.0-puppet) box is hosted from my Dropbox account, so there is a 20GB/day bandwidth limit. While it's unlikely that this threshold will ever be reached, if you do find yourself unable to download this box, you may need to try again the next day.
