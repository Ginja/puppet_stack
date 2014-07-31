class puppet_stack::dependencies::generic {
  $puppet_vardir = $::puppet_stack::puppet_vardir

  rvm_system_ruby { $::puppet_stack::ruby_vers:
      ensure      => 'present',
      default_use => true,
  }

  if ($::puppet_stack::puppet == true)
  or ($::puppet_stack::foreman == true)
  or ($::puppet_stack::smartproxy == true) {
    rvm_gem { 'bundler':
      ensure       => $::puppet_stack::bundler_vers,
      ruby_version => $::puppet_stack::ruby_vers,
      require      => Rvm_system_ruby[$::puppet_stack::ruby_vers],
    }

    rvm_gem { 'passenger':
      ensure       => $::puppet_stack::passenger_vers,
      ruby_version => $::puppet_stack::ruby_vers,
      require      => Rvm_system_ruby[$::puppet_stack::ruby_vers],
    }

    if ($::puppet_stack::puppet == true)
    or ($::puppet_stack::smartproxy == true) {
      rvm_gem { 'rack':
        ensure       => $::puppet_stack::rack_vers,
        ruby_version => $::puppet_stack::ruby_vers,
        require      => Rvm_system_ruby[$::puppet_stack::ruby_vers],
      }
    }
    
    # Needed for Postgresql module
    if ($::puppet_stack::foreman == true)
    and ($::puppet_stack::foreman_db_adapter == 'postgresql')
    and ($::puppet_stack::foreman_db_host == 'localhost') {
      rvm_gem { 'ruby-augeas':
        ensure       => $::puppet_stack::rack_vers,
        ruby_version => $::puppet_stack::ruby_vers,
        require      => Rvm_system_ruby[$::puppet_stack::ruby_vers],
      }
    }

    unless defined(Class['apache']) {
      class { 'apache':
        default_vhost => false,
      }
    }
    contain apache
    contain apache::mod::ssl
    contain apache::mod::headers
  }

  if ($::puppet_stack::puppet == true) {
    unless defined(Group['puppet']) {
        group { 'puppet':
          ensure => 'present',
        }
    }

    unless defined(User['puppet']) {
        user { 'puppet':
          ensure  => 'present',
          comment => 'Puppet Daemon User',
          gid     => 'puppet',
          home    => $puppet_vardir,
          shell   => '/sbin/nologin',
        }
    }
    
    file { $puppet_vardir: 
      ensure  => 'directory',
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0755',
      require => User['puppet'],
    }

    unless defined(Apache::Listen['8140']) {
      apache::listen { '8140': }
    }
  }

  if ($::puppet_stack::foreman ==  true) {
    group { $::puppet_stack::foreman_user:
      ensure => 'present',
    }

    user { $::puppet_stack::foreman_user:
      ensure  => 'present',
      comment => 'Foreman Daemon User',
      gid     => 'foreman',
      groups  => ['puppet'], # Necessary?
      home    => $::puppet_stack::foreman_user_home,
      shell   => '/bin/bash',
    }

    file { $::puppet_stack::foreman_user_home:
      ensure => 'directory',
      owner  => $::puppet_stack::foreman_user,
      group  => $::puppet_stack::params::apache_user,
      mode   => '0750',
    }

    unless defined(Apache::Listen['443']) {
      apache::listen { '443': }
    }
  }

  if ($::puppet_stack::smartproxy ==  true) {
    group { $::puppet_stack::smartp_user:
      ensure => 'present',
    }

    user { $::puppet_stack::smartp_user:
      ensure  => 'present',
      comment => 'Smart-Proxy Daemon User',
      gid     => 'smartproxy',
      groups  => ['puppet'], # Necessary?
      home    => $::puppet_stack::smartp_user_home,
      shell   => '/bin/bash',
    }

    file { $::puppet_stack::smartp_user_home:
      ensure => 'directory',
      owner  => $::puppet_stack::smartp_user,
      group  => $::puppet_stack::params::apache_user,
      mode   => '0750',
    }

    unless defined(Apache::Listen[$::puppet_stack::smartp_port]) {
      apache::listen { $::puppet_stack::smartp_port: }
    }
  }
}
