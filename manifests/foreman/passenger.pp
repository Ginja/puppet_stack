class puppet_stack::foreman::passenger {
  $foreman_user    = $::puppet_stack::foreman_user
  $foreman_app_dir = $::puppet_stack::foreman::foreman_app_dir
  $apache_user     = $::puppet_stack::params::apache_user
  $http_dir        = $::puppet_stack::params::http_dir
  # How you work around Puppet evaluating templates during parsing

  file { "${foreman_app_dir}/tmp":
    ensure  => 'directory',
    owner   => $foreman_user,
    group   => $apache_user,
    mode    => '2770',
  }

  # If root owns the file for some reason
  file { "${foreman_app_dir}/tmp/restart.txt":
    ensure  => 'file',
    owner   => $foreman_user,
    group   => $apache_user,
    mode    => '0644',
    require => File["${foreman_app_dir}/tmp"],
  }

  file { "${http_dir}/conf.d/foreman.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/passenger/foreman.conf.erb'),
    notify  => Service['httpd'],
  }

  exec { 'restart_foreman_app':
    command     => '/bin/touch tmp/restart.txt',
    cwd         => $foreman_app_dir,
    refreshonly => true,
    logoutput   => 'on_failure',
    require     => File["${foreman_app_dir}/tmp/restart.txt"],
  }
}
