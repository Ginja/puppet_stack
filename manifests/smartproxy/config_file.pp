define puppet_stack::smartproxy::config_file (
  $content = { ':enabled' => false },
  $path    = "${::puppet_stack::smartproxy::smartp_app_dir}/config/settings.d",
  $owner   = 'smartproxy',
  $group   = 'smartproxy',
  $mode    = '0444',
) {
  validate_hash($content)
  $valid_files = [ '^bmc.yml$', '^chef.yml$', '^dhcp.yml$', '^dns.yml$', '^puppetca.yml$', '^puppet.yml$', '^realm.yml$', '^tftp.yml$' ]
  validate_re($title, $valid_files, "Invalid smart-proxy config filename. ${title} has to equal one of the following values: 
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
  
  # For settings.yml.erb
  $_settings = $content
  
  file { "${path}/${title}":
    ensure  => 'file',
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('puppet_stack/smartproxy/settings.yml.erb'),
    notify  => Exec['restart_smartproxy_app'],
    require => Exec ['default_puppet.yml', 'default_puppetca.yml'],
  }
}
