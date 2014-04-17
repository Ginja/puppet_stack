class puppet_stack::puppet {
  $puppet_environments_dir = $::puppet_stack::puppet_environments_dir
  $report_to_foreman       = $::puppet_stack::report_to_foreman
  $puppet_role             = $::puppet_stack::puppet_role
  $cert_name               = $::puppet_stack::cert_name
  $ca_server               = $::puppet_stack::ca_server
  $log                     = $report_to_foreman ? {
    true  => 'log, foreman',
    false => 'log'
  }

  if ($::puppet_stack::puppet_ssl_chain == '') {
    $puppet_ssl_chain = $puppet_role ? {
      'catalog' => '/var/lib/puppet/ssl/certs/ca.pem',
      default  => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    }
  }
  else {
    $puppet_ssl_chain = $::puppet_stack::puppet_ssl_chain
  }
  if ($::puppet_stack::puppet_ssl_ca == '') {
    $puppet_ssl_ca = $puppet_role ? {
      'catalog' => '/var/lib/puppet/ssl/certs/ca.pem',
      default  => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    }
  }
  else {
    $puppet_ssl_ca = $::puppet_stack::puppet_ssl_ca
  }
  $puppet_ssl_cert = $::puppet_stack::puppet_ssl_cert ? {
    ''      => "/var/lib/puppet/ssl/certs/${cert_name}.pem",
    default => $::puppet_stack::puppet_ssl_cert,
  }
  $puppet_ssl_key = $::puppet_stack::puppet_ssl_key ? {
    ''      => "/var/lib/puppet/ssl/private_keys/${cert_name}.pem",
    default => $::puppet_stack::puppet_ssl_key,
  }
  $puppet_ssl_ca_revoc = $::puppet_stack::puppet_ssl_ca_revoc ? {
    ''      => '/var/lib/puppet/ssl/ca/ca_crl.pem',
    default => $::puppet_stack::puppet_ssl_ca_revoc
  }
  # Puppet can't support hash literals in selectors yet...
  # https://projects.puppetlabs.com/issues/14301
  # You'll need to specify all puppet_ssl_* params, if ssldir is not $vardir/ssl
  $_empty_hash             = {}
  $_conf_main_catalog      = {
    'ssldir'        => '$vardir/ssl',
    'logdir'        => '/var/log/puppet',
    'privatekeydir' => '$ssldir/private_keys { group = service }',
    'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }',
    'ca_server'     => $ca_server
  }
  $_conf_main_aio_ca       = {
    'ssldir'        => '$vardir/ssl',
    'logdir'        => '/var/log/puppet',
    'privatekeydir' => '$ssldir/private_keys { group = service }',
    'hostprivkey'   => '$privatekeydir/$certname.pem { mode = 640 }'
  }
  $_conf_agent_aio_catalog = {
    'classfile'   => '$vardir/classes.txt',
    'localconfig' => '$vardir/localconfig',
    'report'      => true,
    'listen'      => false,
    'pluginsync'  => true,
    'certname'    => $cert_name,
    'server'      => $cert_name
  }
  $_conf_agent_ca          = {
    'classfile'   => '$vardir/classes.txt',
    'localconfig' => '$vardir/localconfig',
    'report'      => true,
    'listen'      => false,
    'pluginsync'  => true,
    'certname'    => $cert_name
  }
  $_conf_master_aio        = {
    'manifest'        => '$confdir/manifests/',
    'environmentpath' => "\$confdir/${puppet_environments_dir}",
    'modulepath'      => "\$confdir/${puppet_environments_dir}/\$environment/modules:\$confdir/modules",
    'ca'              => true,
    'certname'        => $cert_name,
    'autosign'        => '/etc/puppet/autosign.conf',
    'reports'         => $log
  }
  $_conf_master_catalog    = {
    'manifest'        => '$confdir/manifests/',
    'environmentpath' => "\$confdir/${puppet_environments_dir}",
    'modulepath'      => "\$confdir/${puppet_environments_dir}/\$environment/modules:\$confdir/modules",
    'ca'              => false,
    'certname'        => $cert_name,
    'reports'         => $log
  }
  $_conf_master_ca         = {
    'ca'         => true,
    'certname'   => $cert_name,
    'autosign'   => '/etc/puppet/autosign.conf'
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
