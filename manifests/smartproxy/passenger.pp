class puppet_stack::smartproxy::passenger {
  $smartp_user      = $::puppet_stack::smartp_user
  $smartp_app_dir   = $::puppet_stack::smartproxy::smartp_app_dir
  $apache_user      = $::puppet_stack::params::apache_user
  $http_dir         = $::puppet_stack::params::http_dir

  file { "${smartp_app_dir}/log":
    ensure  => 'directory',
    owner   => $smartp_user,
    group   => $smartp_user,
    mode    => '0750',
  }

  file { "${smartp_app_dir}/tmp":
    ensure  => 'directory',
    owner   => $smartp_user,
    group   => $apache_user,
    mode    => '2770',
  }

  # If root owns the file for some reason
  file { "${smartp_app_dir}/tmp/restart.txt":
    ensure  => 'file',
    owner   => $smartp_user,
    group   => $apache_user,
    mode    => '0644',
    require => File["${smartp_app_dir}/tmp"],
  }

  file { "${http_dir}/conf.d/smartproxy.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/passenger/smartproxy.conf.erb'),
    notify  => Service['httpd'],
  }

  exec { 'restart_smartproxy_app':
    command     => '/bin/touch tmp/restart.txt',
    cwd         => $smartp_app_dir,
    refreshonly => true,
    logoutput   => 'on_failure',
    require     => File["${smartp_app_dir}/tmp/restart.txt"],
  }
}
