class puppet_stack::smartproxy::settings {
  $cert_name       = $::puppet_stack::cert_name
  $smartp_user     = $::puppet_stack::smartp_user
  $smartp_app_dir  = $::puppet_stack::smartproxy::smartp_app_dir
  $smartp_ssl_cert = $::puppet_stack::smartproxy::smartp_ssl_cert
  $smartp_ssl_key  = $::puppet_stack::smartproxy::smartp_ssl_key
  $smartp_ssl_ca   = $::puppet_stack::smartproxy::smartp_ssl_ca
  $puppet_vardir   = $::puppet_stack::puppet_vardir
  
  $_puppet = $::puppet_stack::puppet_role ? {
    'ca'    => false,
    default => true,
  }
  $_puppetca = $::puppet_stack::puppet_role ? {
    'catalog' => false,
    default   => true,
  }
  
  Puppet_stack::Smartproxy::Config_file {
    ensure  => 'present',
    content => { ':enabled' => false },
    path    => "${smartp_app_dir}/config/settings.d",
    owner   => 'smartproxy',
    group   => 'smartproxy',
    mode    => '0444',
  }
  
  file { "${smartp_app_dir}/config/settings.d":
    ensure  => 'directory',
    owner   => $smartp_user,
    group   => $smartp_user,
    mode    => '0775',
    require => Exec['smartproxy_clone_repo'],
  }
  
  unless defined(Puppet_stack::Smartproxy::Config_file['puppet.yml']) {
    puppet_stack::smartproxy::config_file { 'puppet.yml':
     content => {
       ':enabled'                    => $_puppet,
       ':puppet_url'                 => "https://${cert_name}:8140",
       ':puppet_ssl_ca'              => $smartp_ssl_ca,
       ':puppet_ssl_cert'            => $smartp_ssl_cert,
       ':puppet_ssl_key'             => $smartp_ssl_key,
       ':puppet_use_environment_api' => true,
     },
    }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['puppetca.yml']) {
    puppet_stack::smartproxy::config_file { 'puppetca.yml':
     content => {
       ':enabled'           => $_puppetca,
       ':ssldir'            => "${puppet_vardir}/ssl",
       ':puppetdir'         => '/etc/puppet',
       ':puppetca_use_sudo' => true,
       ':sudo_command'      => '/usr/local/rvm/bin/rvmsudo',
     },
    }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['bmc.yml']) {
    puppet_stack::smartproxy::config_file { 'bmc.yml': }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['chef.yml']) {
    puppet_stack::smartproxy::config_file { 'chef.yml': }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['dhcp.yml']) {
    puppet_stack::smartproxy::config_file { 'dhcp.yml': }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['dns.yml']) {
    puppet_stack::smartproxy::config_file { 'dns.yml': }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['realm.yml']) {
    puppet_stack::smartproxy::config_file { 'realm.yml': }
  }
  unless defined(Puppet_stack::Smartproxy::Config_file['tftp.yml']) {
    puppet_stack::smartproxy::config_file { 'tftp.yml': }
  }
}
