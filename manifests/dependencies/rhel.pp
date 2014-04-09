class puppet_stack::dependencies::rhel {
  $rvm_prefix      = $::puppet_stack::rvm_prefix
  $ruby_vers       = $::puppet_stack::ruby_vers
  $passenger_vers  = $::puppet_stack::passenger_vers
  $gempath         = "${rvm_prefix}/gems/${ruby_vers}/gems"
  $gemroot         = "${gempath}/passenger-${passenger_vers}"
  $packages        = [ 'wget', 'git', 'augeas-devel', 'libvirt-devel',
                      'sqlite-devel', 'postgresql-devel',
                      'libcurl-devel', 'httpd-devel', 'apr-devel',
                      'apr-util-devel', 'libyaml-devel' ]
  $passenger_mod   = 'passenger-install-apache2-module'
  $mod_so          = 'mod_passenger.so'
  $passenger_info  = 'passenger-install-apache2-module --snippet'

  # Not very elegant, but it's a work around
  # https://tickets.puppetlabs.com/browse/PUP-1217
  exec { 'yum_group_install':
    command   => 'yum -y groupinstall "Development tools"',
    path      => "${rvm_prefix}/bin:/usr/bin:/usr/sbin:/bin",
    unless    => 'yum grouplist "Development tools" | grep "^Installed Groups"',
    timeout   => '1800',
    logoutput => 'on_failure',
    before    => Exec['install_apache_passenger_module'],
  }

  package { $packages:
    ensure => present,
    before => Exec['install_apache_passenger_module'],
  }

  exec { 'install_apache_passenger_module':
    command     => "rvm ${ruby_vers} exec ${passenger_mod} --auto --languages ruby",
    path        => "${rvm_prefix}/bin:${rvm_prefix}/gems/${ruby_vers}/bin:/usr/bin:/usr/sbin:/bin",
    unless      => "find ${gempath}/passenger-${passenger_vers} -iname ${mod_so} -print | grep ${mod_so}",
    environment => [ 'HOME=/root', ],
    timeout     => 1800,
    logoutput   => on_failure,
    require     => Rvm_system_ruby[$::puppet_stack::ruby_vers],
  }

  file { "${::puppet_stack::params::http_dir}/conf.d/passenger.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/passenger/passenger.conf.erb'),
    before  => Service['httpd'],
    require => Exec['install_apache_passenger_module'],
  }
}
