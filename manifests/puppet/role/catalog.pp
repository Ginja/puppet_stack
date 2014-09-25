class puppet_stack::puppet::role::catalog {
  $ruby_vers               = $::puppet_stack::ruby_vers
  $rvm_prefix              = $::puppet_stack::rvm_prefix
  $puppet_role             = 'catalog'
  $rvm_ruby_root           = "${rvm_prefix}/gems/${ruby_vers}"
  $puppet_cmd              = "${rvm_ruby_root}/bin/puppet"
  $puppet_vardir           = $::puppet_stack::puppet_vardir
  $report_to_foreman       = $::puppet_stack::report_to_foreman
  $use_foreman_as_an_enc   = $::puppet_stack::use_foreman_as_an_enc
  $catalog_cert_autosign   = $::puppet_stack::catalog_cert_autosign
  $cert_name               = $::puppet_stack::cert_name
  
  # Puppet needs permission to create a production environment folder
  file { '/etc/puppet/environments': 
    ensure  => 'directory',
    owner   => 'root',
    group   => 'puppet',
    mode    => '0775',
    require => File['/etc/puppet'],
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/puppet/puppet.conf.erb'),
    notify  => Exec['restart_puppet'],
    require => File['/etc/puppet'],
  }

  file { '/etc/puppet/auth.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/puppet/auth.conf.erb'),
    require => File['/etc/puppet'],
  }

  file { '/etc/puppet/manifests':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/puppet'],
  }

  file { '/etc/puppet/modules':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/puppet'],
  }

  file { '/etc/puppet/manifests/site.pp':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppet_stack/puppet/site.pp.erb'),
    require => File['/etc/puppet'],
  }

  if ($use_foreman_as_an_enc == true) {
    file { '/etc/puppet/node.rb':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/puppet_stack/foreman/node.rb',
      require => File['/etc/puppet'],
    }
  }

  if ($report_to_foreman == true) {
    file { "${rvm_ruby_root}/gems/puppet-${::puppetversion}/lib/puppet/reports/foreman.rb":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/puppet_stack/foreman/foreman.rb',
      require => File['/etc/puppet'],
    }
  }
  
  if ($report_to_foreman == true)
  or ($use_foreman_as_an_enc == true) {
    file { '/etc/puppet/foreman.yaml':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      content => template('puppet_stack/foreman/foreman.yaml.erb'),
      require => File['/etc/puppet'],
    }
  }

  file { "${puppet_vardir}/reports":
    ensure => 'directory',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0750',
  }

  file { "${puppet_vardir}/ssl":
    ensure => 'directory',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0771',
  }

  # May I recommend configuring autosign for your Puppet PMs?
  # If not, you'll need to sign it manually, and re-run your manifest
  exec { 'first_check_in':
    command => "${puppet_cmd} certificate generate --verbose --ca-location remote ${cert_name}",
    unless  => "/usr/bin/test -f ${puppet_vardir}/ssl/certs/${cert_name}.pem",
    returns => [ 0, 1 ], # https://tickets.puppetlabs.com/browse/PUP-2018
    require => File['/etc/puppet', "${puppet_vardir}/ssl"],
  }
}
