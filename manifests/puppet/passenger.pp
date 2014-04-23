class puppet_stack::puppet::passenger {
  $puppet_role               = $::puppet_stack::puppet_role
  $puppet_vardir             = $::puppet_stack::puppet_vardir
  $catalog_cert_autosign     = $::puppet_stack::catalog_cert_autosign
  $puppet_passenger_app_root = $::puppet_stack::puppet_passenger_app_root
  $puppet_passenger_doc_root = $::puppet_stack::puppet_passenger_doc_root
  $apache_user               = $::puppet_stack::params::apache_user
  $http_dir                  = $::puppet_stack::params::http_dir

  file { [ $puppet_passenger_app_root, $puppet_passenger_doc_root ]:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => File["${puppet_passenger_app_root}/config.ru"],
  }

  file { "${puppet_passenger_app_root}/tmp":
    ensure  => 'directory',
    owner   => 'puppet',
    group   => $apache_user,
    mode    => '2770',
    require => File[$puppet_passenger_app_root],
  }

  # If root owns the file for some reason
  file { "${puppet_passenger_app_root}/tmp/restart.txt":
    ensure  => 'file',
    owner   => 'puppet',
    group   => $apache_user,
    mode    => '0644',
    before  => Exec['restart_puppet'],
    require => File["${puppet_passenger_app_root}/tmp"],
  }

  # Could copy from puppet gem, but this is more managable
  file { "${puppet_passenger_app_root}/config.ru":
    ensure  => 'file',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0444',
    content => template('puppet_stack/puppet/config.ru.erb'),
  }

  file { "${http_dir}/conf.d/puppet_master.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/passenger/puppet_master.conf.erb'),
    notify  => Service['httpd'],
    require => File["${puppet_passenger_app_root}/config.ru"],
  }

  exec { 'restart_puppet':
    command     => '/bin/touch tmp/restart.txt',
    cwd         => $puppet_passenger_app_root,
    refreshonly => true,
    logoutput   => on_failure,
  }
}
