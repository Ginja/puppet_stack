class puppet_stack::foreman {
  $foreman_user_home    = $::puppet_stack::foreman_user_home
  $cert_name            = $::puppet_stack::cert_name
  $db                   = $::puppet_stack::foreman_db_adapter
  $foreman_db_host      = $::puppet_stack::foreman_db_host
  $foreman_db_name      = $::puppet_stack::foreman_db_name
  $foreman_db_user      = $::puppet_stack::foreman_db_user
  $foreman_db_password  = $::puppet_stack::foreman_db_password
  $foreman_app_dir = $::puppet_stack::foreman_app_dir ? {
    ''      => "${foreman_user_home}/foreman",
    default => $::puppet_stack::foreman_app_dir,
  }
  $foreman_ssl_cert = $::puppet_stack::foreman_ssl_cert ? {
    ''      => "/var/lib/puppet/ssl/certs/${cert_name}.pem",
    default => $::puppet_stack::foreman_ssl_cert,
  }
  $foreman_ssl_key = $::puppet_stack::foreman_ssl_key ? {
    ''      => "/var/lib/puppet/ssl/private_keys/${cert_name}.pem",
    default => $::puppet_stack::foreman_ssl_key,
  }
  if ($::puppet_stack::foreman_ssl_ca == '') {
    $foreman_ssl_ca = $::puppet_stack::puppet_role ? {
        'catalog' => '/var/lib/puppet/ssl/certs/ca.pem',
        default  => '/var/lib/puppet/ssl/ca/ca_crt.pem',
      }
  }
  else {
    $foreman_ssl_ca = $::puppet_stack::foreman_ssl_ca
  }
  $test = [ 'test', { 'adapter' => 'sqlite3', 'database' => 'db/test.sqlite3', 'pool' => '5', 'timeout' => '5000' } ]
  $dev  = [ 'development', { 'adapter' => 'sqlite3', 'database' => 'db/development.sqlite3', 'pool' => '5', 'timeout' => '5000' } ]
  if ($::puppet_stack::foreman_db_config == []) {
    $foreman_db_config = $db ? {
      'sqlite3'    => [
                        $test,
                        $dev,
                        [ 'production', { 'adapter' => 'sqlite3', 'database' => 'db/production.sqlite3', 'pool' => '5', 'timeout' => '5000' } ]
                      ],
      'postgresql' => [
                        $test,
                        $dev,
                        [ 'production', { 'adapter' => 'postgresql', 'encoding' => 'unicode', 'host' => $foreman_db_host, 'database' => $foreman_db_name, 'pool' => '25', 'timeout' => '5000', 'username' => $foreman_db_user, 'password' => $foreman_db_password } ]
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
