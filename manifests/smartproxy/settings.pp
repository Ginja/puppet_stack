class puppet_stack::smartproxy::settings {
  $rvm_prefix      = $::puppet_stack::rvm_prefix
  $cert_name       = $::puppet_stack::cert_name
  $smartp_user     = $::puppet_stack::smartp_user
  $smartp_app_dir  = $::puppet_stack::smartproxy::smartp_app_dir
  $smartp_ssl_cert = $::puppet_stack::smartproxy::smartp_ssl_cert
  $smartp_ssl_key  = $::puppet_stack::smartproxy::smartp_ssl_key
  $smartp_ssl_ca   = $::puppet_stack::smartproxy::smartp_ssl_ca
  $puppet_vardir   = $::puppet_stack::puppet_vardir
  
  $_puppet_enabled = $::puppet_stack::puppet_role ? {
    'ca'    => false,
    default => true,
  }
  $_puppetca_enabled = $::puppet_stack::puppet_role ? {
    'catalog' => false,
    default   => true,
  }
  
  # This folder and its contents won't do anything if the smart-proxy is at version 1.5
  file { "${smartp_app_dir}/config/settings.d":
    ensure  => 'directory',
    owner   => $smartp_user,
    group   => $smartp_user,
    mode    => '0775',
    require => Exec['smartproxy_clone_repo'],
  }
  
  # Can't use "unless defined..." conditionals as it places confusing restrictions
  # on where users specify puppet_stack::smartproxy::config_file resources

  # Set defaults ONLY if files don't exist
  exec { 'default_puppet.yml': 
    command => "/bin/cat << EOF > ${smartp_app_dir}/config/settings.d/puppet.yml
---
##########################################
# PLACED BY PUPPET. CONTENTS NOT MANAGED #
##########################################
# You must restart the web app after changing any of these values
# because they are cached at startup
:enabled: ${_puppet_enabled}
:puppet_url: https://${cert_name}:8140
:puppet_ssl_ca: ${smartp_ssl_ca}
:puppet_ssl_cert: ${smartp_ssl_cert}
:puppet_ssl_key: ${smartp_ssl_key}
:puppet_use_environment_api: true
EOF",
    user    => $smartp_user,
    creates => "${smartp_app_dir}/config/settings.d/puppet.yml",
    require => File["${smartp_app_dir}/config/settings.d"],
  }
  exec { 'default_puppetca.yml': 
    command => "/bin/cat << EOF > ${smartp_app_dir}/config/settings.d/puppetca.yml
---
##########################################
# PLACED BY PUPPET. CONTENTS NOT MANAGED #
##########################################
# You must restart the web app after changing any of these values
# because they are cached at startup
:enabled: ${_puppetca_enabled}
:ssldir: ${puppet_vardir}/ssl
:puppetdir: /etc/puppet
:puppetca_use_sudo: true
:sudo_command: ${rvm_prefix}/bin/rvmsudo  
EOF",
    user    => $smartp_user,
    creates => "${smartp_app_dir}/config/settings.d/puppetca.yml",
    require => File["${smartp_app_dir}/config/settings.d"],
  }

}
