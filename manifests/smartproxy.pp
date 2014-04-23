class puppet_stack::smartproxy {
  $rvm_prefix       = $::puppet_stack::rvm_prefix
  $puppet_vardir    = $::puppet_stack::puppet_vardir
  $cert_name        = $::puppet_stack::cert_name
  $smartp_user_home = $::puppet_stack::smartp_user_home
  $smartp_port      = $::puppet_stack::smartp_port
  $puppetca = $::puppet_stack::puppet_role ? {
    'catalog' => false,
    'none'    => false,
    default   => true,
  }
  $puppet = $::puppet_stack::puppet_role ? {
    'catalog' => true,
    'aio'     => true,
    default   => false,
  }
  $smartp_app_dir = $::puppet_stack::smartp_app_dir ? {
    ''      => "${smartp_user_home}/smart-proxy",
    default => $::puppet_stack::smartp_app_dir,
  }
  $smartp_log_file = $::puppet_stack::smartp_log_file ? {
    ''      => "${smartp_app_dir}/log/app.log",
    default => $::puppet_stack::smartp_log_file # You better make sure this folder exists
  }
  $smartp_ssl_cert = $::puppet_stack::smartp_ssl_cert ? {
    ''      => "${puppet_vardir}/ssl/certs/${cert_name}.pem",
    default => $::puppet_stack::smartp_ssl_cert,
  }
  $smartp_ssl_key = $::puppet_stack::smartp_ssl_key ? {
    ''      => "${puppet_vardir}/ssl/private_keys/${cert_name}.pem",
    default => $::puppet_stack::smartp_ssl_key,
  }
  if ($::puppet_stack::smartp_ssl_ca== '') {
    $smartp_ssl_ca= $::puppet_stack::puppet_role ? {
      'catalog' => "${puppet_vardir}/ssl/certs/ca.pem",
      default   => "${puppet_vardir}/ssl/ca/ca_crt.pem",
    }
  }
  else {
    $smartp_ssl_ca= $::puppet_stack::smartp_ssl_ca
  }
  if ($::puppet_stack::smartp_settings == {}) {
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
      ':ssldir'          => "${puppet_vardir}/ssl",
      ':puppetdir'       => '/etc/puppet',
      ':puppet'          => $puppet,
      ':chefproxy'       => false,
      ':bmc'             => false,
      ':log_file'        => $smartp_log_file,
      ':log_level'       => 'ERROR'
    }
  }
  else {
    $smartp_settings = $::puppet_stack::smartp_settings
  }

  class { 'puppet_stack::smartproxy::base': }
  -> class { 'puppet_stack::smartproxy::passenger': }
  contain 'puppet_stack::smartproxy::base'
  contain 'puppet_stack::smartproxy::passenger'
}
