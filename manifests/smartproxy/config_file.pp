define puppet_stack::smartproxy::config_file (
  $ensure,
  $content = { ':enabled' => false },
  $file    = $title,
  $path    = "${::puppet_stack::smartproxy::smartp_app_dir}/config/settings.d",
  $owner   = 'smartproxy',
  $group   = 'smartproxy',
  $mode    = '0444',
) {
  validate_hash($content)
  validate_re($ensure, ['^present$', '^absent$'], 'The ensure parameter has to be one of the following values: present, absent')
  $valid_files = [ '^bmc.yml$', '^chef.yml$', '^dhcp.yml$', '^dns.yml$', '^puppetca.yml$', '^puppet.yml$', '^realm.yml$', '^tftp.yml$' ]
  validate_re($name, $valid_files, "Invalid smart-proxy config filename. ${file} has to equal one of the following values: 
  bmc.yml,
  chef.yml,
  dhcp.yml,
  dns.yml,
  puppetca.yml,
  puppet.yml,
  realm.yml,
  tftp.yml")
  validate_string($path)
  validate_string($owner)
  validate_string($group)
  validate_string($mode)

  $_ensure = $ensure ? {
    'present' => 'file',
    'absent'  => 'absent',
  }
  # For settings.yml.erb
  $_settings = $content
  
  file { "${path}/${name}":
    ensure  => $_ensure,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('puppet_stack/smartproxy/settings.yml.erb'),
    notify  => Exec['restart_smartproxy_app'],
    require => [ Exec['smartproxy_clone_repo'], File["${::puppet_stack::smartproxy::smartp_app_dir}/config/settings.d"] ],
  }
}
