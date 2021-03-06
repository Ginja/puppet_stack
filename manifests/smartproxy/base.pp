class puppet_stack::smartproxy::base {
  $rvm_prefix       = $::puppet_stack::rvm_prefix
  $ruby_vers        = $::puppet_stack::ruby_vers
  $bundle_install   = 'bundle install --path vendor'
  $touch_complete   = "echo ${ruby_vers} > vendor/.${ruby_vers}.bundle.install.complete"
  $smartp_user      = $::puppet_stack::smartp_user
  $smartp_user_home = $::puppet_stack::smartp_user_home
  $smartp_repo      = $::puppet_stack::smartp_repo
  $smartp_app_dir   = $::puppet_stack::smartproxy::smartp_app_dir
  $apache_user      = $::puppet_stack::params::apache_user
  $_settings        = $::puppet_stack::smartproxy::smartp_settings

  exec { 'smartproxy_clone_repo':
    command => "/usr/bin/git clone ${smartp_repo[url]}",
    user    => $smartp_user,
    path    => "${rvm_prefix}/gems/${ruby_vers}/bin:/usr/bin:/bin",
    cwd     => $smartp_user_home,
    creates => $smartp_app_dir,
    logoutput => 'on_failure',
  }
  
  unless ($smartp_repo[tag] == false) {
    exec { 'smartproxy_checkout_version':
      command     => "/usr/bin/git checkout -b ${smartp_repo[tag]}-checkout ${smartp_repo[tag]}",
      user        => $smartp_user,
      cwd         => $smartp_app_dir,
      logoutput   => 'on_failure',
      refreshonly => true,
      before      => [ File["${smartp_app_dir}/config/settings.yml", '/etc/sudoers.d/smartproxy'], Exec['smartproxy_bundle_install'] ],
      subscribe   => Exec['smartproxy_clone_repo'],
    }
  }

  file { "${smartp_app_dir}/config/settings.yml":
    ensure  => 'file',
    owner   => $smartp_user,
    group   => $smartp_user,
    mode    => '0444',
    content => template('puppet_stack/smartproxy/settings.yml.erb'),
    notify  => Exec['restart_smartproxy_app'],
    require => Exec['smartproxy_clone_repo'],
  }

  file { '/etc/sudoers.d/smartproxy':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template('puppet_stack/smartproxy/smartproxy.erb'),
  }

  exec { 'smartproxy_bundle_install':
    command     => "${rvm_prefix}/bin/rvm ${ruby_vers} do ${bundle_install} && ${touch_complete}",
    user        => $smartp_user,
    path        => "${rvm_prefix}/gems/${ruby_vers}/bin:/usr/bin:/bin",
    cwd         => $smartp_app_dir,
    environment => [ "HOME=${smartp_user_home}", ],
    timeout     => 1800,
    logoutput   => 'on_failure',
    creates     => "${smartp_app_dir}/vendor/.${ruby_vers}.bundle.install.complete",
    require     => File["${smartp_app_dir}/config/settings.yml"],
  }
}
