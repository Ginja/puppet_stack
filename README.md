#puppet_stack

[![Build Status](https://travis-ci.org/Ginja/puppet_stack.svg?branch=master)](https://travis-ci.org/Ginja/puppet_stack)

##Table of Contents

1. [Overview - What does this module do?](#overview)
  * [Why Should You Use This Module?](#why-should-you-use-this-module)
2. [Requirements - What does this module require?](#requirements)
3. [Usage - How do I use this module?](#usage)
  * [Sample Class Configurations - Resource examples](#sample-class-configurations)
  * [Sample Define Configurations - Resource examples](#sample-define-configurations)
4. [Parameters - A definition of each module parameter](#parameters)
  * [Class: puppet_stack](#class-puppet_stack)
  * [Define Type: puppet_stack::puppet::environment](#define-type-puppet_stackpuppetenvironment)
  * [Define Type: puppet_stack::smartproxy::config_file](#define-type-puppet_stacksmartproxyconfig_file)
5. [Additional Notes - Things to be aware of](#additional-notes)
6. [Troubleshooting - What to do when things go awry](#troubleshooting)
  * [Tips](#tips)
  * [FAQ](#faq)
7. [Development - What you need to know to contribute](#development)
  * [Versioning](#versioning)
  * [Branching](#branching)
  * [Testing](#testing)
  * [Vagrant](#vagrant)

##Overview

This module will help you install, and manage the following:

* A Puppet Master
* The Foreman
* smart-proxy

This module also understands that a Puppet Master can have different roles:

1. An all-in-one (aio), which is a Puppet Master that serves out catalogs and is a Certificate Authority (CA).
2. A Puppet Catalog Master (catalog), which is a Puppet Master that only serves out client catalogs.
3. A Puppet CA server (ca), which is a Puppet Master that only manages client certificates.

###Why Should You Use This Module?

Where this module differs from other similar modules is that each software stack is configured using RVM, git repos, and gems, instead of yum packages and the default system Ruby. What this offers is a greater degree of modularity, and control when performing upgrades.

Other reasons are:

* If you don't like mucking about with your OS' Ruby installation.
* If you want to stay on top of Ruby security patches.
* If you want to easily switch between different versions of Passenger.
* If you want to use git commands to update your applications.

##Requirements
Before you use this module, you'll require a machine with the following:

* [Multi-User RVM installation](https://rvm.io/rvm/install#installation):
```bash
sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | sudo bash -s stable
```
* An RVM Ruby installation (> 1.8.7), which has been set as the system default:
```bash
rvm install ruby-2.0.0
rvm alias create default ruby-2.0.0
```
* Bundler installation for your RVM Ruby installation is required by the Puppet module:
```bash
gem install bundler
```
* Puppet Gem (3.4.0+) installation for your RVM Ruby installation:
```bash
gem install puppet
```

You can easily include all of this in a kickstart script, or do it yourself manually.

This module is quite dependent on other modules, which is not best practice, but it sure is convenient and extremely hard to avoid. The current module dependency list is:

* dependency 'puppetlabs/apache', '1.x'
* dependency 'puppetlabs/concat', '1.x'
* dependency 'puppetlabs/postgresql', '3.x'
* dependency 'maestrodev-rvm', '1.5.x'
* dependency 'puppetlabs/stdlib', '>=3.2.0 <5.0.0'

At this time, this module is only compatible with the RedHat OS family (i.e. RHEL, CentOS, Scientific Linux, etc..).

##Usage
This module has a lot of parameters to help you configure the finer details for each application, most of which have a default value. There are however, two required parameters: 

* ruby_vers, the value of which should be what RVM Ruby version you've installed (including patch number, '#.#.#-p###')
* passenger_vers, the value of which should be the version of Passenger you want to install/use

This module will most likely be the the first thing you run on a server. So the following is an example of how you may want to do that:

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
puppet module install Ginja-puppet_stack --target-dir ~/puppet/modules

# Create a site.pp that contains the Puppet resources you want to apply
vi ~/puppet/manifests/site.pp

# Apply the manifest
puppet apply --verbose --modulepath ~/puppet/modules --detailed-exitcodes ~/puppet/manifests/site.pp
```

This module assumes SELINUX will be set to permissive. However, if you want to use it with SELINUX (i.e. enforcing), you should follow the above instructions, and then do the following:

* Install the management utilities for SELINUX:
```bash
yum install policycoreutils-python
```
* Start using your new stack (ex: access URLs, add a client, sign a certificate, etc...)
* Generate a new SELINUX policy module:
```bash
# You can name the policy module anything you want (we're calling it puppet in this case) 
# I recommend changing the name based on what you're trying to allow (ex: foreman, smart-proxy, etc...)
grep httpd /var/log/audit/audit.log | audit2allow -M puppet
```
* Apply the policy module:
```bash
semodule -i puppet.pp
```
* Set SELINUX back to enforcing:
```bash
setenforce 1
```
* Test

This should certainly help, but you may find that additional SELINUX adjustments are required. Use `chcon`, or try your hand at applying another policy module.

###Sample Class Configurations

An all-in-one Puppet Master, with the Foreman using a Postgres database, and smart-proxy. This is an overly verbose declaration, but its intent is to show you what you can do.

```puppet
class { 'puppet_stack':
  ruby_vers               => 'ruby-2.0.0-p451',
  passenger_vers          => '4.0.40',
  global_passenger_options => {
    'PassengerDefaultUser'        => 'apache',
    'PassengerFriendlyErrorPages' => 'on',
    'PassengerMaxPoolSize'        => '4',
    'PassengerMaxRequests'        => '10000',
  },
  puppet_role             => 'aio',
  conf_main               => {
    'vardir'        => '/var/lib/puppet',
    'ssldir'        => '$vardir/ssl',
    'logdir'        => '/var/log/puppet',
    'privatekeydir' => '$ssldir/private_keys { group = service }',
    'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
    'certname'      => 'puppet3.domain.com',
    'pluginsync'    => 'true',
  },
  conf_master             => {
    'default_manifest' => './manifests',
    # This enables directory environments in Puppet open source
    'environmentpath'  => '$confdir/environments',
    'reports'          => 'log, foreman',
  },
  conf_agent              => {
    'report'      => 'true',
    'listen'      => 'false',
    'environment' => 'production',
  },
  puppet_vhost_options     => {
    'PassengerHighPerformance' => 'on',
    'PassengerMinInstances'    => '2',
    'PassengerPreStart'        => 'https://puppet.domain.com:8140',
  },
  use_foreman_as_an_enc   => true,
  upload_facts_to_foreman => true,
  report_to_foreman       => true,
  foreman                 => true,
  foreman_repo            => {
    'url' => 'https://github.com/theforeman/foreman.git -b 1.6-stable',
    'tag' => '1.6.1',
  },
  foreman_db_adapter      => 'postgresql',
  foreman_db_host         => 'localhost',
  foreman_db_name         => 'foreman',
  foreman_db_user         => 'foreman',
  foreman_db_password     => 'somedbpassword',
  foreman_vhost_options   => {
    'PassengerHighPerformance' => 'on',
    'PassengerMinInstances'    => '2',
    'PassengerPreStart'        => 'https://puppet.domain.com',
  },
  foreman_settings        => {
    ':unattended'                              => false,
    ':login'                                   => true,
    ':require_ssl'                             => true,
    ':locations_enabled'                       => false,
    ':organizations_enabled'                   => false,
    ':support_jsonp'                           => false,
    ':restrict_registered_puppetmasters'       => true,
    ':require_ssl_puppetmasters'               => true,
    ':email_reply_address'                     => 'foreman-no-reply@domain.com',
    ':trusted_puppetmaster_hosts'              => [ 'puppet3.domain.com' ],
    ':foreman_url'                             => 'https://puppet3.domain.com',
    ':unattended_url'                          => 'https://puppet3.domain.com',
    ':create_new_host_when_facts_are_uploaded' => true,
    ':create_new_host_when_report_is_uploaded' => true,
    ':websockets_encrypt'                      => 'on',
    ':websockets_ssl_cert'                     => '/var/lib/puppet/ssl/certs/puppet3.domain.com.pem',
    ':websockets_ssl_key'                      => '/var/lib/puppet/ssl/private_keys/puppet3.domain.com.pem',
    ':ssl_ca_file'                             => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ':ssl_certificate'                         => '/var/lib/puppet/ssl/certs/puppet3.domain.com.pem',
    ':ssl_priv_key'                            => '/var/lib/puppet/ssl/private_keys/puppet3.domain.com.pem',
  },
  smart_proxy             => true,
  smartp_repo             => {
    'url' => 'https://github.com/theforeman/smart-proxy.git -b 1.6-stable',
    'tag' => '1.6.1',
  }
  smartp_settings         => {
    ':ssl_certificate' => '/var/lib/puppet/ssl/certs/puppet3.domain.com.pem',
    ':ssl_ca_file'     => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ':ssl_private_key' => '/var/lib/puppet/ssl/private_keys/puppet3.domain.com.pem',
    ':trusted_hosts'   => [ 'puppet3.domain.com' ],
    ':daemon'          => true,
    ':https_port'      => '8443',
    ':log_file'        => '/usr/share/smartproxy/smart-proxy/log/app.log',
    ':log_level'       => 'ERROR',
  },
}

# Creating directory or dynamic environments
# May I suggest looking into r10k instead?

puppet_stack::puppet::environment { 'production': 
  ensure => 'present',
}

puppet_stack::puppet::environment { 'development': 
  ensure => 'present',
}

# Specifying configuration files for smart-proxy

puppet_stack::smartproxy::config_file { 'puppet.yml':
  content => {
    ':enabled'                    => true,
    ':puppet_url'                 => 'https://puppet3.domain.com:8140',
    ':puppet_ssl_ca'              => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ':puppet_ssl_cert'            => '/var/lib/puppet/ssl/certs/puppet3.domain.com.pem',
    ':puppet_ssl_key'             => '/var/lib/puppet/ssl/private_keys/puppet3.domain.com.pem',
    ':puppet_use_environment_api' => true,
  },
}

puppet_stack::smartproxy::config_file { 'puppetca.yml':
  content => {
    ':enabled'           => true,
    ':ssldir'            => '/var/lib/puppet/ssl',
    ':puppetdir'         => '/etc/puppet',
    ':puppetca_use_sudo' => true,
    ':sudo_command'      => '/usr/local/rvm/bin/rvmsudo',
  },
}
```

A Puppet CA server, with smart-proxy, and no Foreman:

When bringing up a CA Master, you must set the pm_server attribute to the FQDN of your Puppet Master that will serve out catalogs. That is unless you're specifying your own [conf_master hash](#conf_master); in which case, you then must include a 'server' key in the hash. 

In the example below, we assume puppet-pm1.domain.com is our Puppet Master that serves out catalogs.

```puppet
class { 'puppet_stack':
  ruby_vers           => 'ruby-2.0.0-p451',
  passenger_vers      => '4.0.40',
  puppet_role         => 'ca',
  pm_server           => 'puppet-pm1.domain.com',
  foreman             => false,
  smart_proxy         => true,
  autosign_entries    => [ 'puppet3-pm1.domain.com' ],
  smartp_settings     => {
    ':ssl_certificate' => '/var/lib/puppet/ssl/certs/puppet3-ca.domain.com.pem',
    ':ssl_ca_file'     => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ':ssl_private_key' => '/var/lib/puppet/ssl/private_keys/puppet3-ca.domain.com.pem',
    ':trusted_hosts'   => [ 'puppet3-pm1.domain.com' ],
    ':daemon'          => true,
    ':https_port'      => '8443',
    ':log_file'        => '/usr/share/smartproxy/smart-proxy/log/app.log',
    ':log_level'       => 'ERROR'
  },
}
```

A Puppet Catalog Master, with the Foreman, and smart-proxy: 

When bringing up a Catalog Master, you must set the ca_server attribute to the FQDN of your Puppet CA server. That is unless you're specifying your own [conf_master hash](#conf_master); in which case, you then must include a 'ca_server' key in the hash. 

In the example below, we assume puppet-ca.domain.com is our CA server, and that it contains an autosign entry for our Catalog Master (ex: puppet3-pm1.domain.com). If you do not wish to use autosigning, set [catalog_cert_autosign](#catalog_cert_autosign) to false, sign the certificate for your Catalog Master manually after the first Puppet run, and then start a second Puppet run to finish.

```puppet
class { 'puppet_stack':
  ruby_vers               => 'ruby-2.0.0-p451',
  passenger_vers          => '4.0.40',
  puppet_role             => 'catalog',
  ca_server               => 'puppet-ca.domain.com',
  catalog_cert_autosign   => true,
  use_foreman_as_an_enc   => true,
  upload_facts_to_foreman => true,
  report_to_foreman       => true,
  foreman                 => true,
  foreman_db_adapter      => 'postgresql',
  foreman_db_password     => 'dbpassword',
  foreman_settings        => {
    ':unattended'                              => false,
    ':login'                                   => true,
    ':require_ssl'                             => true,
    ':locations_enabled'                       => false,
    ':organizations_enabled'                   => false,
    ':support_jsonp'                           => false,
    ':restrict_registered_puppetmasters'       => true,
    ':require_ssl_puppetmasters'               => true,
    ':email_reply_address'                     => 'foreman-no-reply@domain.com',
    ':trusted_puppetmaster_hosts'              => [ 'puppet3-pm1.domain.com', 'puppet3-ca.domain.com' ],
    ':foreman_url'                             => 'https://puppet3-pm1.domain.com',
    ':unattended_url'                          => 'https://puppet3-pm1.domain.com',
    ':create_new_host_when_facts_are_uploaded' => true,
    ':create_new_host_when_report_is_uploaded' => true,
    ':websockets_encrypt'                      => 'on',
    ':websockets_ssl_cert'                     => '/var/lib/puppet/ssl/certs/puppet3-pm1.domain.com.pem',
    ':websockets_ssl_key'                      => '/var/lib/puppet/ssl/private_keys/puppet3-pm1.domain.com.pem',
    ':ssl_ca_file'                             => '/var/lib/puppet/ssl/certs/ca.pem',
    ':ssl_certificate'                         => '/var/lib/puppet/ssl/certs/puppet3-pm1.domain.com.pem',
    ':ssl_priv_key'                            => '/var/lib/puppet/ssl/private_keys/puppet3-pm1.domain.com.pem',
  },
  smart_proxy             => true,
  smartp_settings         => {
    ':ssl_certificate' => '/var/lib/puppet/ssl/certs/puppet3-pm1.domain.com.pem',
    ':ssl_ca_file'     => '/var/lib/puppet/ssl/certs/ca.pem',
    ':ssl_private_key' => '/var/lib/puppet/ssl/private_keys/puppet3-pm1.domain.com.pem',
    ':trusted_hosts'   => [ 'puppet3-pm1.domain.com' ],
    ':daemon'          => true,
    ':https_port'      => '8443',
    ':log_file'        => '/usr/share/smartproxy/smart-proxy/log/app.log',
    ':log_level'       => 'ERROR'
  },
}
```



You can even use this module to install just the Foreman and/or smart-proxy. In this case, the default location values for the SSL certificates are assumed to be in /etc/puppet/ssl and not in /var/lib/puppet/ssl. This is because it's presumed that the node is a client rather than some sort of Puppet Master. If this is not true for you, you must manually specify the location of the SSL certificates using the {foreman,smartp}_ssl_* parameters.

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  puppet         => false,
  foreman        => true,
  smartproxy     => false,
}
```

You can use this module to scale out your Puppet infrastructure, but explaining how to do so is out of the scope of this document. However, here are some things to consider:

* How many servers do you plan to use? And how you will split them up (ex: 2 catalog servers, 1 CA)?
* How will you distribute the load (ex: HAProxy, appliance-based solution)?
* How will you keep your manifests and module in sync across your catalog masters (ex: GlusterFS, rsync)?
* Will you be using an ENC (ex: the Foreman, PuppetDB)?

For more information on this topic, see this [page](https://docs.puppetlabs.com/guides/scaling_multiple_masters.html).

###Sample Define Configurations

####puppet_stack::puppet::environment

As of Puppet 3.5, there are currently two types of environments in Puppet:

* [Config-file environments](http://docs.puppetlabs.com/puppet/3.5/reference/environments_classic.html)
* [Directory environments](http://docs.puppetlabs.com/puppet/3.5/reference/environments.html#directory-environments-vs-config-file-environments)

There are dynamic environments as well, but they're similar to directory environments. I've covered how to use them as well below.

For the record, here is [PuppetLabs'](http://docs.puppetlabs.com/puppet/3.5/reference/environments.html#directory-environments-vs-config-file-environments) opinion on environments:

> ... directory environments, [are] easier to use and will eventually replace config file environments completely. However, in Puppet 3.5, they cannot:
>* Set config_version per-environment
>* Change the order of the modulepath or remove parts of it
>Those features are coming in Puppet 3.6.

In this module, config-file environments are specified using the [conf_envs](#conf_envs) parameter, while directory and dynamic environments are specified using a define type:

```puppet
puppet_stack::puppet::environment { 'production': 
  ensure => 'present',
}

puppet_stack::puppet::environment { 'development': 
  ensure => 'present',
}

```

The end result of these two resources would be the following directory tree underneath /etc/puppet/environments:

```
/etc/puppet
 \- environments
     \- production
     |   \- modules/
     |   |   \- ...
     |   \- manifests/
     |   |   \- ...
     \- development
     |   \- modules/
     |   |   \- ...
     |   \- manifests/
     |   |   \- ...
  ...
```

In Puppet 3.4.x directory environments don't exist. There are however [dynamic environments](http://docs.puppetlabs.com/puppet/3.5/reference/environments_classic.html#dynamic-environments), which are similar. To use dynamic environments with this module, you need to specify the following in your puppet.conf file:

```ini
[master]
  ...
  manifest = $confdir/environments/$environment/manifests
  modulepath = $confdir/environments/$environment/modules
```

An example of how to do this:

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  puppet_role    => 'aio',
  conf_master    => {
    'manifest'   => '$confdir/environments/$environment/manifests',
    'modulepath' => '$confdir/environments/$environment/modules',
    'ca'         => true,
    'autosign'   => '/etc/puppet/autosign.conf',
    'reports'    => 'log',
  }
  foreman        => false,
  smartproxy     => false,
}
```

Once this is set, you can use puppet_stack::puppet::environment to place dynamic environments.

Directory environments in Puppet 3.5.1 and later are [disabled by default](http://docs.puppetlabs.com/puppet/3.5/reference/environments.html#enabling-directory-environments). To use directory environments with this module, you need to set the environmentpath in your puppet.conf file:

```ini
[main]
  ...
  environmentpath = $confdir/environments
```

An example of how to do this:

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  puppet_role    => 'aio',
  conf_main      => {
    'ssldir'          => '$vardir/ssl',
    'logdir'          => '/var/log/puppet',
    'privatekeydir'   => '$ssldir/private_keys { group = service }',
    'hostprivkey'     => '$privatekeydir/$certname.pem { mode = 640 }',
    'server'          => 'hostname.domain.com',
    'certname'        => 'hostname.domain.com',
    'environmentpath' => '$confdir/environments',
  }
  foreman        => false,
  smartproxy     => false,
}
```

Once this is set, you can use puppet_stack::puppet::environment to place directory environments.

Be aware that by default, directory environments: 

* use [directory-as-manifest type behaviour](http://docs.puppetlabs.com/puppet/3.5/reference/dirs_manifest.html#directory-behavior-vs-single-file), so an environment's manifests directory should be filled with individual *.pp files; one for each of your Puppet clients. Unless you're using an ENC like the Foreman.
* [will effectively disable all config-file environments](http://docs.puppetlabs.com/puppet/3.5/reference/environments_classic.html#no-interaction-with-directory-environments).

####puppet_stack::smartproxy::config_file

As of smart-proxy 1.6, the configurations for each of smart-proxy's modules have been broken out into their own file (inside config/settings.d). This define type allows you to configure each one individually. By default, all configuration files will be placed on disk, but will be disabled until specified otherwise. 

You MUST set the title for each resource to one of the following values:

* bmc.yml
* chef.yml
* dhcp.yml
* dns.yml
* puppetca.yml
* puppet.yml
* realm.yml
* tftp.yml

```puppet
puppet_stack::smartproxy::config_file { 'puppetca.yml':
  content => {
    ':enabled'           => true,
    ':ssldir'            => '/var/lib/puppet/ssl',
    ':puppetdir'         => '/etc/puppet',
    ':puppetca_use_sudo' => true,
    ':sudo_command'      => '/usr/local/rvm/bin/rvmsudo',
  },
}
```
It will be up to to you to ensure you don't specify anything illegal in the content attribute. A list of available options for each file can be found in [smart-proxy's documentation](http://theforeman.org/manuals/1.6/index.html#4.3.2SmartProxySettings).

If you specify an older version of smart-proxy (ex: 1.5), you will need to use the [smartp_settings](#smartp_settings) parameter to specify all options.

##Parameters

###Class: puppet_stack

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

####`augeas_vers`
The version of the ruby-augeas gem you want to install (defaults to present). Can also be set to a version number.

####`global_passenger_options`
Global Passenger options that you want to apply globally to all web applications (defaults to an empty hash, which is none). Values specified will be put into /etc/{http/apache2}/conf.d/passenger.conf. 

Example:

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  ...
  global_passenger_options => {
    'PassengerDefaultUser'        => 'apache',
    'PassengerFriendlyErrorPages' => 'on',
    'PassengerMinInstances'       => '3'
  }
  ...
}
```

Result:

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

It's up to you to make sure you don't put any invalid or virtual host specific Passenger option here. Refer to [this documentation](http://www.modrails.com/documentation/Users%20guide%20Apache.html) for configuring Passenger.

####`puppet`
If false (defaults to true), will prevent any type of Puppet Master from being configured.

####`puppet_role`
Specifies the type of Puppet Master to configure (defaults to aio). Valid options are aio (all-in-one), ca, and catalog.

####`puppet_vardir`
Used to specify the $vardir for your Puppet installation (defaults to /var/lib/puppet). This value is used to set the :puppetdir in /etc/puppet/foreman.yaml (if it's being placed, see [use_foreman_as_an_enc](#use_foreman_as_an_enc), and [report_to_foreman](#report_to_foreman)), and will be set as the home of the Puppet user if you're not already managing that user resource yourself.

####`cert_name`
The certificate name for the server (defaults to $::fqdn).

####`ca_server`
Specifies the CA server to use (defaults to undef). Only needs to be set if puppet_role is set to catalog, and if the default conf_main settings are used. If you're specifying your own [conf_master hash](#conf_master), be sure to include a 'ca_server' key. 

####`pm_server`
Specifies the puppet master server to use for puppet agent runs (defaults to undef). Only needs to be set if puppet_role is set to ca, and if the default conf_main settings are used. If you're specifying your own [conf_master hash](#conf_master), be sure to include a 'server' key. You can also specify a 'server' key in the [conf_agent hash](#conf_agent).

####`autosign_entries`
An array of [Puppet autosign](http://docs.puppetlabs.com/puppet/3.5/reference/ssl_autosign.html) entries to put into /etc/puppet/autosign.conf (defaults to an empty array).

####`site_pp_entries`
An array of entries to put into the default site manifest, /etc/puppet/manifests/site.pp (defaults to ['node default {}']). It's often common to put import statements in this file, but be aware that as of Puppet 3.5 import statements are [deprecated](http://docs.puppetlabs.com/puppet/3.5/reference/lang_import.html).

####`auth_conf_entries`
A string to specify any extra auth.conf entries (defaults to an empty string). Documentation for auth.conf can be found [here](https://docs.puppetlabs.com/guides/rest_auth_conf.html).

```puppet
class { 'puppet_stack':
  ruby_vers         => 'ruby-2.0.0-p451',
  passenger_vers    => '4.0.40',
  ...
  auth_conf_entries => '
# This is a comment

path /facts
method find, search
auth yes
allow custominventory.site.net, devworkstation.site.net

# An exception allowing one authenticated workstation to access any endpoint

path /
auth yes
allow devworkstation.site.net',
  ...
}
```

####`catalog_cert_autosign`
If true (defaults to false), a catalog master will attempt to fetch its certificate from the specified CA server. For this to work an autosign entry for the Puppet Catalog Master needs to exist on the CA server (see the advanced example in the usage section).

####`conf_main`
A hash of configuration options to put into the [main] section of /etc/puppet/puppet.conf. If left unspecified, it defaults to two different values depending on what Puppet role you've chosen:

```ruby
# Default [main] settings for the catalog role
$conf_main_catalog = {
  'vardir'        => $puppet_vardir,
  'ssldir'        => '$vardir/ssl',
  'logdir'        => '/var/log/puppet',
  'privatekeydir' => '$ssldir/private_keys { group = service }',
  'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
  'server'        => $pm_server,
  'certname'      => $cert_name,
  'ca_server'     => $ca_server
}
# Defaults [main] settings for the aio, and ca role
$conf_main_aio_ca  = {
  'vardir'        => $puppet_vardir,
  'ssldir'        => '$vardir/ssl',
  'logdir'        => '/var/log/puppet',
  'privatekeydir' => '$ssldir/private_keys { group = service }',
  'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
  'server'        => $pm_server,
  'certname'      => $cert_name
}
```

It's up to you to make sure you don't put any invalid Puppet configuration option. Refer to the appropriate configuration reference document for the Puppet version you are using. To get you started, [here is the one for Puppet 3.5.1](http://docs.puppetlabs.com/references/3.5.1/configuration.html).

####`conf_agent`
A hash of configuration options to put into the [agent] section of /etc/puppet/puppet.conf. If left unspecified, it defaults to the following:

```ruby
$conf_agent = {
  'report'      => true,
  'listen'      => false,
  'pluginsync'  => true,
}
```

It's up to you to make sure you don't put any invalid Puppet configuration option. Refer to the appropriate configuration reference document for the Puppet version you are using. To get you started, [here is the one for Puppet 3.5.1](http://docs.puppetlabs.com/references/3.5.1/configuration.html).

####`conf_master`
A hash of configuration options to put into the [master] section of /etc/puppet/puppet.conf. If left unspecified, it defaults to several different values depending on what Puppet role you've chosen:

```ruby
# Defaults [master] settings for the aio role
$conf_master_aio = {
  'manifest'   => $manifest, # Default value depends on Puppet version
  'modulepath' => '$confdir/modules',
  'ca'         => true,
  'autosign'   => '/etc/puppet/autosign.conf',
  'reports'    => $log # Default value depends on report_to_foreman value
}
# Defaults [master] settings for the catalog role
$conf_master_catalog = {
  'manifest'   => $manifest, # Default value depends on Puppet version
  'modulepath' => '$confdir/modules',
  'ca'         => false,
  'reports'    => $log # Default value depends on report_to_foreman value
}
# Defaults [master] settings for the ca role
$conf_master_ca = {
  'ca'       => true,
  'autosign' => '/etc/puppet/autosign.conf'
}
```
It's up to you to make sure you don't put any invalid Puppet configuration option. Refer to the appropriate configuration reference document for the Puppet version you are using. To get you started, [here is the one for Puppet 3.5.1](http://docs.puppetlabs.com/references/3.5.1/configuration.html).

####`conf_envs`
An array that allows you to specify [config-file environments](http://docs.puppetlabs.com/puppet/3.5/reference/environments_classic.html) in /etc/puppet/puppet.conf (defaults to an empty array, which is none). Acceptable values must be in this format: 

[ [ 'string', {hash} ] ]

Example:

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  ...
  conf_envs => [
    [ 'production', { 'manifest' => '$confdir/manifests/site.pp' } ],
    [ 'development', { 'manifest' => '$confdir/manifests/site.pp' } ]
  ],
  ...
}
```

####`puppet_vhost_options`
The vhost options that you want to apply to Puppet (defaults to an empty hash, which means none). Values specified will be put into the /etc/{http/apache2}/conf.d/puppet_master.conf file.

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
If true (defaults to false), will place /etc/puppet/node.rb (and subsequently /etc/puppet/foreman.yaml), and set the following options in the [master] section of /etc/puppet/puppet.conf:

```ini
[master]
  ...
  external_nodes = /etc/puppet/node.rb
  node_terminus = exec
```

If you want to use your own ENC script, set this to false, place your script, and specify the proper keys/values in your conf_master hash.

If this is set to true, additional work will be needed to use the Foreman as an ENC. See the Foreman note in [Additional Notes](#additional-notes) section.

####`upload_facts_to_foreman`
If true (defaults to false), sets the appropriate value in /etc/puppet/foreman.yaml that trigger the uploading of a client's Facter facts when they check-in. You will also need to set the foreman_url parameter if the Foreman is not on the local machine.

####`foreman_url`
The URL of your Foreman instance (defaults to https://$::fqdn). This value must start with either http:// or https://, and is used in /etc/puppet/foreman.yaml.

####`report_to_foreman`
If true (defaults to false), will place ${rvm_ruby_root}/gems/puppet-${::puppetversion}/lib/puppet/reports/foreman.rb (and subsequently /etc/puppet/foreman.yaml), which will allow a Puppet Master to send client reports to the Foreman. If you've specified your own [conf_master](#conf_master) hash, and you wish to upload client reports to the Foreman, you will need to add foreman as a value to your reports key.

Example:

```puppet
class { 'puppet_stack':
  ruby_vers      => 'ruby-2.0.0-p451',
  passenger_vers => '4.0.40',
  puppet_role    => 'aio',
  conf_master    => {
    'manifest'   => '/etc/puppet/manifests/site.pp',
    'modulepath' => '$confdir/modules',
    'ca'         => true,
    'autosign'   => '/etc/puppet/autosign.conf',
    'reports'    => 'log, foreman',
  },
  ...
}
```

What the [master] section of puppet.conf will look like afterwards:

```ini
[master]
  manifest = /etc/puppet/manifests/site.pp
  modulepath = $confdir/modules
  ca = true
  autosign = /etc/puppet/autosign.conf
  reports = log, foreman
```

####`foreman`
If true (defaults to false), will configure the Foreman.

####`foreman_repo`
A hash specifying the git repository from which to clone the Foreman. It also can accept a tag key to checkout a specific version/commit. Defaults to the 1.6.1 tag of the 1.6-stable branch.

```ruby
{ 
  'url' => 'https://github.com/theforeman/foreman.git -b 1.6-stable',
  'tag' => '1.6.1',
}
```

####`foreman_user`
The user that Passenger will run the Foreman under (defaults to foreman).

####`foreman_user_home`
The home of the foreman_user (defaults to /usr/share/foreman).

####`foreman_app_dir`
The application directory for the Foreman (defaults to ${foreman_user_home}/foreman). This should be the directory where foreman_repo clones to.

####`foreman_settings`
A hash of configuration options that will be put into the Foreman's config/settings.yaml file. Defaults settings are:

```ruby
# From manifests/params.pp
$foreman_settings = {
  ':unattended'            => false,
  ':login'                 => true,
  ':require_ssl'           => true,
  ':locations_enabled'     => false,
  ':organizations_enabled' => false,
  ':support_jsonp'         => false,
}
```

As you can see, the Foreman is set just to be an ENC by default (:unattended => false). If you wish to change any of the default values, specify your own hash. You can set defaults for other [Foreman settings](http://theforeman.org/manuals/1.5/index.html#3.5.2ConfigurationOptions) here as well:

```puppet
class { 'puppet_stack':
  ...
  foreman_settings => {
    ':unattended'                 => false,
    ':login'                      => true,
    ':require_ssl'                => true,
    ':locations_enabled'          => false,
    ':organizations_enabled'      => false,
    ':support_jsonp'              => false,
    ':trusted_puppetmaster_hosts' => ['puppet-pm.domain.com', 'puppet-ca.domain.com'],
  },
  ...
}
```

####`foreman_default_password`
The default password for the admin user (defaults to changeme). This will only be used if the Foreman version is 1.6+. The default password for every other version is 'changeme'.

####`foreman_try_rake_tasks`
Specifies whether or not you want this module to attempt the Foreman's rake tasks (defaults to true). Reasons to set this to false are if you want to run them manually, or if you're bringing up a secondary instance and you're sharing a database.

####`foreman_db_adapter`
The type of database adapter that the Foreman will use. Valid values are postgresql, and sqlite3 (default). If postgresql is specified, this module will use the puppetlabs-postgresql module to install and configure a database.

If you would like to customize the Postgres installation, see the [Additional Notes](#additional-notes) section.

####`foreman_db_host`
The host where the Foreman's database resides (defaults to localhost). If this is not set to localhost, this module will assume the remote host and its database are ready to go, and will attempt to rake it.

####`foreman_db_name`
The name of the database the Foreman will use (defaults to foreman).

####`foreman_db_pool`
The database pool size (defaults to 25).

####`foreman_db_timeout`
The database timeout value (defaults to 5000).

####`foreman_db_user`
The user the Foreman will use to access the database (defaults to foreman).

####`foreman_db_password`
The password for the foreman_db_user (defaults to undef). This must be set if foreman_db_adapater is set to anything other than sqlite3.

####`foreman_db_config`
An array of values that will be used to generate the Foreman's config/database.yml file. Defaults to the following values:

```puppet
# From manifests/foreman.pp
# Shown for brevity & completeness
$test = [ 'test',
          { 'adapter'  => 'sqlite3',
            'database' => 'db/test.sqlite3',
            'pool'     => $foreman_db_pool,
            'timeout'  => $foreman_db_timeout 
          }
        ]
$dev  = [ 'development',
          { 'adapter'  => 'sqlite3',
            'database' => 'db/development.sqlite3',
            'pool'     => $foreman_db_pool,
            'timeout'  => $foreman_db_timeout 
          }
        ]
$sqlite3    = [
                $test,
                $dev,
                [ 'production',
                  { 'adapter'  => 'sqlite3',
                    'database' => 'db/production.sqlite3',
                    'pool'     => $foreman_db_pool,
                    'timeout'  => $foreman_db_timeout 
                  }
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
                    'pool'     => $foreman_db_pool,
                    'timeout'  => $foreman_db_timeout,
                    'username' => $foreman_db_user,
                    'password' => $foreman_db_password 
                  }
                ]
              ]
```

If you were to specify your own values here, it should look similar to the following:

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
  ...
}
```

####`foreman_vhost_options`
The vhost options that you want to apply to the Foreman (defaults to an empty hash, which means none). Values specified will be put into the /etc/{http/apache2}/conf.d/foreman.conf file.

####`foreman_vhost_server_name`
The ServerName value in the Foreman's vhost file.

####`foreman_ssl_cert`
The SSL certificate file that the Foreman will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`foreman_ssl_key`
The SSL key file that the Foreman will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`foreman_ssl_ca`
The SSL ca file that the Foreman will use. This value defaults to the one that Puppet will create or receive (in the case of a catalog master). Generally you should leave this option alone. If you plan on using your own certificate, or if you're not configuring Puppet with this module, you will need to ensure that this file on the disk before httpd is started.

####`smartproxy`
If false (defaults to true), will prevent smart-proxy from being configured.

####`smartp_repo`
A hash specifying the git repository from which to clone smart-proxy. It also can accept a tag key to checkout a specific version/commit. Defaults to the 1.6.1 tag of the 1.6-stable branch.

```ruby
{ 
  'url' => 'https://github.com/theforeman/smart-proxy.git -b 1.6-stable',
  'tag' => '1.6.1',
}
```

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
A hash of configuration options that will be put into smart-proxy's config/settings.yml file. If you override a single value, you will need to specify everything (and be sure to prepend your keys with ':'). The default settings are for smart-proxy 1.6.

```puppet
# From manifests/smartproxy.pp
$smartp_settings = {
  ':ssl_certificate' => $smartp_ssl_cert,
  ':ssl_private_key' => $smartp_ssl_key,
  ':ssl_ca_file'     => $smartp_ssl_ca,
  ':trusted_hosts'   => [ $::fqdn ],
  ':daemon'          => true,
  ':https_port'      => $smartp_port,
  ':log_file'        => $smartp_log_file,
  ':log_level'       => 'ERROR'
}
```

You will NEED to set this parameter manually to something like below if you plan on using smart-proxy 1.5 (you cannot use anything lower, see [Additional Notes](#additional-notes)).

```puppet
class { 'puppet_stack':
  ...
  # An example ONLY for smart-proxy 1.5
  smartp_settings => {
    ':ssl_certificate' => '/var/lib/puppet/ssl/certs/puppet3.domain.com',
    ':ssl_private_key' => '/var/lib/puppet/ssl/private_keys/puppet3.domain.com.pem',
    ':ssl_ca_file'     => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ':trusted_hosts'   => [ $::fqdn ],
    # sudo_command must be specified, and set to RVM's rvmsudo script
    ':sudo_command'    => '/usr/local/rvm/bin/rvmsudo',
    ':daemon'          => true,
    ':port'            => '8443',
    ':tftp'            => false,
    ':dns'             => false,
    ':puppetca'        => true, # or false if you're deploying a Puppet Catalog server
    ':ssldir'          => '/var/lib/puppet/ssl',
    ':puppetdir'       => '/etc/puppet',
    ':puppet'          => true, # or false if you're deploying a Puppet CA server
    ':chefproxy'       => false,
    ':bmc'             => false,
    ':log_file'        => '/usr/share/smartproxy/smart-proxy/log/app.log',
    ':log_level'       => 'ERROR'
  },
  ...
}
```

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

###Define Type: puppet_stack::puppet::environment

####`ensure`
The state of the directory environment. Acceptable values are 'present' and 'absent'. WARNING, if you set this to absent, it will forcibly remove all files/folders in an environment (i.e. modules and manifests).

####`env_name`
The name of the directory environment (defaults to the title of the resource). This value will be scrutinized to ensure it conforms to an [acceptable environment name](http://docs.puppetlabs.com/puppet/3.5/reference/environments.html#allowed-names).

####`owner`
The owner of the directory environment folders (defaults to root).

####`group`
The group of the directory environment folders (defaults to puppet).

####`mode`
The mode of the directory environment folders (defaults to 0755).

###Define Type: puppet_stack::smartproxy::config_file

####`content`
A hash containing the options to specify in the configuration file. Defaults to:

```ruby
{ ':enabled' => false }
```

####`path`
A string containing the path of where to place the configuration file (defaults to "${::puppet_stack::smartproxy::smartp_app_dir}/config/settings.d"). 

####`owner`
A string specifying which user should be the owner of the configuration file (defaults to smartproxy).

####`group`
A string specifying which group should be set for the configuration file (defaults to smartproxy).

####`mode`
A string specifying the mode for the configuration file (defaults to 0444).

##Additional Notes

* The lowest smartproxy version you can use is 1.5. This is because it contains 2 important patches. The first allows you to specify which sudo command to use [1](https://github.com/theforeman/smart-proxy/commit/3824d182ed364cbc844138e4d107c9336fd4c756), and the second allows for trusted_hosts to be specified when using Passenger [2](https://github.com/theforeman/smart-proxy/commit/04148e799c23d7b2024dfb812d04f803f80449da).

* There are several seams in this module for the: Apache, Postgresql, /etc/puppet, and /var/lib/puppet resources that allow you to override them. For example, you could specify the following if you did not want the Apache module to install the default Apache modules and conf.d files, and you wanted /etc/puppet to be a symlink:

```puppet
  # You MUST declare any overrides BEFORE the puppet_stack resource
  file { '/etc/puppet': 
    ensure => 'symlink',
    target => '/some/target',
  }
  class { 'apache':
    default_mods        => false,
    default_confd_files => false,
  }

  class { 'puppet_stack':
    ruby_vers      => 'ruby-2.0.0-p451',
    passenger_vers => '4.0.40',
    ...
  }
```

* This module does not manage any type of firewall. You will need to open up the appropriate ports yourself. The ports, if left at their default values, are: 443 (Foreman), 8140 (Puppet), and 8443 (smart-proxy).

* Some exec resources may take a long time to finish depending on your Internet connection. Therefore certain exec resources have had their timeout attribute increased to 30 minutes. Don't be worried if your first Puppet run seems to be stalled.

* All you need to do to switch Passenger versions is change the value for [passenger_vers](#passenger_vers). Doing so will install the new version as a gem, run `passenger-install-apache2-module`, update conf.d/passenger.conf with the appropriate values, and restart Apache.

* In order to properly use the Foreman as an ENC and with smart-proxies, you will need to manually specify all of your Puppet Masters in the trusted_puppetmaster_hosts array setting. This can be done through the [foreman_settings](#foreman_settings) parameter, or from within the application (Administer->Settings->Auth). You will also need to add the Puppet Master that hosts the Foreman instance (if applicable, the Foreman can be run on its run own server).

* As of version 1.0.0, the foreman and smartproxy parameter are now set to false by default. This is to prevent accidental configuration of either application. I'd rather have them both be opt-in than opt-out. You should know what you're going to have installed!

##Troubleshooting

A lot of work has been put into this module to prevent the most commons of pitfalls, but like [life](https://www.youtube.com/watch?v=SkWeMvrNiOM), problems will find a way too.

###Tips

When you're troubleshooting a problem related to the Foreman or smart-proxy, it's best to become the user they're configured under (by default: foreman, and smartproxy). Both accounts do not have a password set, but their shells are both set to /bin/bash, so you can log into them from root:

```bash
sudo su - foreman
# OR
sudo su - smartproxy
```

If you ever need to run any rake tasks for the Foreman manually, here they are:

```bash
# Assuming you're at the root of the Foreman repo,
# and are already the correct user for the application
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake db:seed assets:precompile locale:pack RAILS_ENV=production
```
 
###FAQ

1. One of the bundle install tasks failed!
  * This is most likely due to a development library package not being installed, which may be because of a new gem in the Gemfile. Check the output to see which one it is, and search for it using your local package manager. Usually these packages end with -devel.
2. One of the Foreman's rake tasks failed!
  * db:migrate
    * A common reason this tasks fails is because either the database wasn't ready, the credentials in config/database.yml are incorrect (Postgres), or file permissions (SQLite). Check that the database is available, and the credentials are correct. And if you're using SQLite, check that the Foreman user can create a .sqlite3 file where you've specified.
  * db:seed
    * This rake task usually fails because your machine doesn't have a proper FQDN. Check to make sure that `facter fqdn` doesn't return an empty value. This usually is only an issue when testing with Vagrant, and you're most likely missing a domain. To resolve this add 'domain local' to /etc/resolv.conf. However, if you're experiencing a problem with this task outside of Vagrant, please submit an [issue](https://github.com/Ginja/puppet_stack/issues).
3. The Puppet Master didn't create or receive (catalog) its own certificate!
  * The commands responsible for carrying out this task uses `facter fqdn` for the default cert_name value. So if the Facter fqdn fact is empty, these commands will fail. You can either fix this by specifying a different certificate name using the [cert_name](#cert_name) parameter, or better yet, by ensuring `facter fqdn` returns something; as it's used in other parts of the module (see above).
4. Something just isn't working!
  * Things to check:
    * SELINUX is set as you expect. Try setting it to permissive if it's set to enforcing, and see if the problem goes away. If it does, use chcon, or apply an SELINUX policy module to correct the issue (assuming you want to use SELINUX).
    * Logs, logs, logs. Check the relevant logs for whatever is broken. Some are located in the Apache log directory, and other's may be located within the application repo (ex: /usr/share/foreman/foreman/log/production.log). 
 * Still stuck? Feel free to submit an [issue](https://github.com/Ginja/puppet_stack/issues) and include as much information as you can (ex: log snippets, what version of the module you're using, OS, etc...).

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
bundle exec rake spec
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
sudo puppet module install Ginja-puppet_stack --target-dir ./modules
```

Edit the Vagrantfile. Use the following example wholesale or as a template:

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
  
  # "Forwarded ports allow you to access a port on your host machine and have all 
  # data forwarded to a port on the guest machine, over either TCP or UDP."
  # https://docs.vagrantup.com/v2/networking/forwarded_ports.html
  # Example: http(s)://127.0.0.1:host_port
  config.vm.network :forwarded_port, host: 4580, guest: 80
  config.vm.network :forwarded_port, host: 4581, guest: 443
  config.vm.network :forwarded_port, host: 4582, guest: 8443
  config.vm.network :forwarded_port, host: 4583, guest: 8140

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

Add Puppet resources to manifests/site.pp:

Example:

```puppet
class { 'puppet_stack':
  ruby_vers                => 'ruby-2.0.0-p451',
  passenger_vers           => '4.0.40',
  global_passenger_options => {
    'PassengerDefaultUser'        => 'apache',
    'PassengerFriendlyErrorPages' => 'on',
    'PassengerMinInstances'       => '2'
  },
  puppet                   => true,
  puppet_role              => 'aio',
  foreman                  => true,
  foreman_db_adapter       => 'postgresql',
  foreman_db_password      => 'suchsecurity',
  smartproxy               => true,
}
```

Bring up the box, and watch the magic happen:

```bash
vagrant up
```

The [ginja/centos-6.5-x64-rvm-ruby2.0.0-puppet](https://vagrantcloud.com/ginja/centos-6.5-x64-rvm-ruby2.0.0-puppet) box is hosted from my Dropbox account, so there is a 20GB/day bandwidth limit. While it's unlikely that this threshold will ever be reached, if you do find yourself unable to download this box, you may need to try again the next day. The Packer template used to create this box can be found in my [packer-templates](https://github.com/Ginja/packer-templates) repo.
