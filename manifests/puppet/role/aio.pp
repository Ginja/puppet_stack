class puppet_stack::puppet::role::aio {
  $ruby_vers               = $::puppet_stack::ruby_vers
  $rvm_prefix              = $::puppet_stack::rvm_prefix
  $puppet_role             = 'aio' # all in one
  $puppet_environments_dir = $::puppet_stack::puppet_environments_dir
  $rvm_ruby_root           = "${rvm_prefix}/gems/${ruby_vers}"
  $puppet_cmd              = "${rvm_ruby_root}/bin/puppet"
  $report_to_foreman       = $::puppet_stack::report_to_foreman
  $use_foreman_as_an_enc   = $::puppet_stack::use_foreman_as_an_enc
  $cert_name               = $::puppet_stack::cert_name
  # Graciously borrowed from https://github.com/stephenrjohnson/puppetmodule/blob/master/manifests/passenger.pp
  $cert_clean_cmd          = "${puppet_cmd} cert clean ${cert_name}"
  $cert_gen_cmd            = "${puppet_cmd} certificate --ca-location=local --dns_alt_names=puppet generate ${cert_name}"
  $cert_sign_cmd           = "${puppet_cmd} cert sign --allow-dns-alt-names ${cert_name}"
  $cert_find_cmd           = "${puppet_cmd} certificate --ca-location=local find ${cert_name}"

  file { '/etc/puppet':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  
  file { $puppet_environments_dir: 
    ensure  => 'directory',
    owner   => 'root',
    group   => 'puppet',
    mode    => '0755',
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

  file { '/etc/puppet/autosign.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'puppet',
    mode    => '0664',
    content => template('puppet_stack/puppet/autosign.conf.erb'),
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
      content => template('puppet_stack/foreman/node.rb.erb'),
      require => File['/etc/puppet'],
    }
  }

  if ($report_to_foreman == true) {
    file { "${rvm_ruby_root}/gems/puppet-${::puppetversion}/lib/puppet/reports/foreman.rb":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      content => template('puppet_stack/foreman/foreman.rb.erb'),
      require => File['/etc/puppet'],
    }
  }

  file { '/var/lib/puppet/reports':
    ensure => 'directory',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0750',
  }

  file { '/var/lib/puppet/ssl':
    ensure => 'directory',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0771',
    before => File['/var/lib/puppet/ssl/ca'],
  }

  file{ [ '/var/lib/puppet/ssl/ca', '/var/lib/puppet/ssl/ca/requests' ]:
    ensure => 'directory',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0770',
    before => Exec['generate_ca_cert'],
  }

  exec { 'generate_ca_cert':
    command   => "${cert_clean_cmd} ; ${cert_gen_cmd} && ${cert_sign_cmd} && ${cert_find_cmd}",
    unless    => "/usr/bin/test -f `${puppet_cmd} config print ssldir`/certs/${cert_name}.pem",
    logoutput => on_failure,
    require   => File['/etc/puppet/puppet.conf'],
  }
}
