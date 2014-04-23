class puppet_stack::foreman {
  $puppet_vardir        = $::puppet_stack::puppet_vardir
  $ssldir               = $::puppet_stack::puppet ? {
    true  => $puppet_vardir,
    false => '/etc/puppet',
  }
  $foreman_user_home    = $::puppet_stack::foreman_user_home
  $cert_name            = $::puppet_stack::cert_name
  $db                   = $::puppet_stack::foreman_db_adapter
  $foreman_db_host      = $::puppet_stack::foreman_db_host
  $foreman_db_name      = $::puppet_stack::foreman_db_name
  $foreman_db_pool      = $::puppet_stack::foreman_db_pool
  $foreman_db_timeout   = $::puppet_stack::foreman_db_timeout
  $foreman_db_user      = $::puppet_stack::foreman_db_user
  $foreman_db_password  = $::puppet_stack::foreman_db_password
  $foreman_app_dir = $::puppet_stack::foreman_app_dir ? {
    ''      => "${foreman_user_home}/foreman",
    default => $::puppet_stack::foreman_app_dir,
  }
  $foreman_ssl_cert = $::puppet_stack::foreman_ssl_cert ? {
    ''      => "${$ssldir}/ssl/certs/${cert_name}.pem",
    default => $::puppet_stack::foreman_ssl_cert,
  }
  $foreman_ssl_key = $::puppet_stack::foreman_ssl_key ? {
    ''      => "${$ssldir}/ssl/private_keys/${cert_name}.pem",
    default => $::puppet_stack::foreman_ssl_key,
  }
  if ($::puppet_stack::foreman_ssl_ca == '') {
    $foreman_ssl_ca = $::puppet_stack::puppet ? {
      true    => "${ssldir}/ssl/ca/ca_crt.pem",
      default => "${ssldir}/ssl/certs/ca.pem", 
    }
  }
  else {
    $foreman_ssl_ca = $::puppet_stack::foreman_ssl_ca
  }
  $test = [ 'test', 
            { 'adapter'  => 'sqlite3', 
              'database' => 'db/test.sqlite3', 
              'pool'     => $foreman_db_pool, 
              'timeout'  => $foreman_db_timeout } 
          ]
  $dev  = [ 'development', 
            { 'adapter'  => 'sqlite3', 
              'database' => 'db/development.sqlite3', 
              'pool'     => $foreman_db_pool, 
              'timeout'  => $foreman_db_timeout } 
          ]
  if ($::puppet_stack::foreman_db_config == []) {
    $foreman_db_config = $db ? {
      'sqlite3'    => [
        $test,
        $dev,
        [ 'production', 
          { 'adapter'  => 'sqlite3', 
            'database' => 'db/production.sqlite3', 
            'pool'     => $foreman_db_pool, 
            'timeout'  => $foreman_db_timeout } ]
      ],
      'postgresql' => [
        $test,
        $dev,
        [ 'production', 
          { 'adapter'  => 'postgresql', 
            'encoding' => 'unicode', 
            'host'     => $foreman_db_host, 
            'database' => $foreman_db_name, 
            'pool'     => $foreman_db_pool, 
            'timeout'  => $forman_db_timeout, 
            'username' => $foreman_db_user, 
            'password' => $foreman_db_password } 
        ]
      ],
    }
  }
  else {
    $foreman_db_config = $::puppet_stack::foreman_db_config
  }

  if ($foreman_db_host == 'localhost')
  and ($foreman_db_adapter == 'postgresql') {
      class { 'puppet_stack::foreman::base': }
      -> class { "puppet_stack::foreman::database::${db}": }
      -> class { 'puppet_stack::foreman::rake': }
      -> class { 'puppet_stack::foreman::passenger': }
      contain 'puppet_stack::foreman::base'
      contain "puppet_stack::foreman::database::${db}"
      contain 'puppet_stack::foreman::rake'
      contain 'puppet_stack::foreman::passenger'
  }
  else {
    class { 'puppet_stack::foreman::base': }
    -> class { 'puppet_stack::foreman::rake': }
    -> class { 'puppet_stack::foreman::passenger': }
    contain 'puppet_stack::foreman::base'
    contain 'puppet_stack::foreman::rake'
    contain 'puppet_stack::foreman::passenger'
  }
}
