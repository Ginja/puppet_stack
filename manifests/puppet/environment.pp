define puppet_stack::puppet::environment ( 
  $ensure,
  $env_name = $title,
  $owner    = 'root',
  $group    = 'puppet',
  $mode     = '0755'
) {
  validate_re($env_name, '\A[a-z0-9_]+\Z', 'You\'ve specified an illegal environment name. It has to pass this regex: /\A[a-z0-9_]+\Z/')
  if ($env_name =~ /main|master|agent|user/) {
    fail('You\'ve specified an illegal environment name. It cannot match any of the following: main, master, agent, user')
  }
  validate_string($owner)
  validate_string($group)
  validate_string($mode)
  validate_re($ensure, ['^present$', '^absent$'], 'The ensure parameter has to be one of the following values: present, absent')

  $_ensure = $ensure ? {
    'present' => 'directory',
    'absent'  => 'absent',
  }
  
  file { "/etc/puppet/environments/${env_name}": 
    ensure  => $_ensure,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    force   => true,
    require => File['/etc/puppet/environments'],
  }
  
  if ($ensure == 'present') { 
    file { "/etc/puppet/environments/${env_name}/modules": 
      ensure  => $_ensure,
      owner   => $owner,
      group   => $group,
      mode    => $mode,
      require => File["/etc/puppet/environments/${env_name}"],
    }
    
    file { "/etc/puppet/environments/${env_name}/manifests": 
      ensure  => $_ensure,
      owner   => $owner,
      group   => $group,
      mode    => $mode,
      require => File["/etc/puppet/environments/${env_name}"],
    }
  }
}
