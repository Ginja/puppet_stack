class puppet_stack::puppet {
  $puppet_vardir           = $::puppet_stack::puppet_vardir
  $report_to_foreman       = $::puppet_stack::report_to_foreman
  $puppet_role             = $::puppet_stack::puppet_role
  $cert_name               = $::puppet_stack::cert_name
  $ca_server               = $::puppet_stack::ca_server
  $pm_server               = $::puppet_stack::pm_server ? {
    undef   => $::fqdn,
    default => $::puppet_stack::pm_server
  }
  $log                     = $report_to_foreman ? {
    true  => 'log, foreman',
    false => 'log'
  }
  $manifest                = $::puppetversion ? {
    /3[.]4[.]\d+/ => '$confdir/manifests/site.pp',
    default       => '$confdir/manifests/'
  }

  if ($::puppet_stack::puppet_ssl_chain == '') {
    $puppet_ssl_chain = $puppet_role ? {
      'catalog' => "${puppet_vardir}/ssl/certs/ca.pem",
      default   => "${puppet_vardir}/ssl/ca/ca_crt.pem",
    }
  }
  else {
    $puppet_ssl_chain = $::puppet_stack::puppet_ssl_chain
  }
  if ($::puppet_stack::puppet_ssl_ca == '') {
    $puppet_ssl_ca = $puppet_role ? {
      'catalog' => "${puppet_vardir}/ssl/certs/ca.pem",
      default  => "${puppet_vardir}/ssl/ca/ca_crt.pem",
    }
  }
  else {
    $puppet_ssl_ca = $::puppet_stack::puppet_ssl_ca
  }
  $puppet_ssl_cert = $::puppet_stack::puppet_ssl_cert ? {
    ''      => "${puppet_vardir}/ssl/certs/${cert_name}.pem",
    default => $::puppet_stack::puppet_ssl_cert,
  }
  $puppet_ssl_key = $::puppet_stack::puppet_ssl_key ? {
    ''      => "${puppet_vardir}/ssl/private_keys/${cert_name}.pem",
    default => $::puppet_stack::puppet_ssl_key,
  }
  $puppet_ssl_ca_revoc = $::puppet_stack::puppet_ssl_ca_revoc ? {
    ''      => "${puppet_vardir}/ssl/ca/ca_crl.pem",
    default => $::puppet_stack::puppet_ssl_ca_revoc
  }
  # Puppet can't support hash literals in selectors yet...
  # https://projects.puppetlabs.com/issues/14301
  # You'll need to specify all puppet_ssl_* params, if ssldir is not $vardir/ssl
  $_empty_hash = {}
  $_conf_main_catalog = {
    'ssldir'        => '$vardir/ssl',
    'logdir'        => '/var/log/puppet',
    'privatekeydir' => '$ssldir/private_keys { group = service }',
    'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
    'server'        => $pm_server,
    'certname'      => $cert_name,
    'ca_server'     => $ca_server
  }
  $_conf_main_aio_ca = {
    'ssldir'        => '$vardir/ssl',
    'logdir'        => '/var/log/puppet',
    'privatekeydir' => '$ssldir/private_keys { group = service }',
    'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
    'server'        => $pm_server,
    'certname'      => $cert_name
  }
  $_conf_agent_aio_catalog = {
    'classfile'   => '$vardir/classes.txt',
    'localconfig' => '$vardir/localconfig',
    'report'      => true,
    'listen'      => false,
    'pluginsync'  => true,
  }
  $_conf_agent_ca = {
    'classfile'   => '$vardir/classes.txt',
    'localconfig' => '$vardir/localconfig',
    'report'      => true,
    'listen'      => false,
    'pluginsync'  => true,
  }
  $_conf_master_aio = {
    'manifest'   => $manifest,
    'modulepath' => '$confdir/modules',
    'ca'         => true,
    'autosign'   => '/etc/puppet/autosign.conf',
    'reports'    => $log
  }
  $_conf_master_catalog = {
    'manifest'   => $manifest,
    'modulepath' => '$confdir/modules',
    'ca'         => false,
    'reports'    => $log
  }
  $_conf_master_ca = {
    'ca'       => true,
    'autosign' => '/etc/puppet/autosign.conf'
  }

  if ($::puppet_stack::conf_main == {}) {
      $conf_main = $puppet_role ? {
        'catalog' => $_conf_main_catalog,
        default   => $_conf_main_aio_ca,
      }
  }
  else {
    $conf_main = $::puppet_stack::conf_main
  }

  if ($::puppet_stack::conf_agent == {}) {
      $conf_agent = $puppet_role ? {
        /(aio|catalog)/ => $_conf_agent_aio_catalog,
        'ca'            => $_conf_agent_ca,
        'none'          => $_empty_hash,
      }
  }
  else {
    $conf_agent = $::puppet_stack::conf_agent
  }

  if ($::puppet_stack::conf_master == {}) {
      $conf_master = $puppet_role ? {
        'aio'     => $_conf_master_aio,
        'catalog' => $_conf_master_catalog,
        'ca'      => $_conf_master_ca,
        'none'    => $_empty_hash,
      }
  }
  else {
    $conf_master = $::puppet_stack::conf_master
  }

  class { "puppet_stack::puppet::role::${puppet_role}": }
  -> class { 'puppet_stack::puppet::passenger': }
  contain "puppet_stack::puppet::role::${puppet_role}"
  contain 'puppet_stack::puppet::passenger'
}
