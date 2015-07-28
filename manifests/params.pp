class puppet_stack::params {
  # 3.4.x because we use contain
  validate_re($::puppetversion, '^3[.](4|5|6|7|8)[.]\d+', "Invalid Puppet version. The puppet_stack module will only run on versions that have been tested (=>3.4.x <=3.7.x) - version: ${::puppetversion}. Modify at your own risk.")
  # Because 1.8.x should not be used anymore. They're all EOL!
  validate_re($::rubyversion, '^(1|2)[.][^8][.]\d+', "You should not be using Ruby ${::rubyversion} with this module. Please install a newer version of Ruby, or just use your available distro packages.")

  # Failures should be caught by puppet_stack::dependecies class
  $apache_user = $::osfamily ? {
    'RedHat' => 'apache',
    'Debian' => 'www-data',
    default  => undef,
  }
  $http_dir    = $::osfamily ? {
    'RedHat' => '/etc/httpd',
    'Debian' => '/etc/apache2',
    default  =>  undef,
  }

  $rvm_prefix     = '/usr/local/rvm'
  $bundler_vers   = 'present'
  $rack_vers      = 'present'
  $augeas_vers    = 'present'

  # PUPPET MASTER #
  $puppet_role               = 'aio'
  $puppet_vardir             = '/var/lib/puppet'
  $cert_name                 = $::fqdn
  $site_pp_entries           = [ 'node default {}' ]
  $puppet_passenger_app_root = '/etc/puppet/rack'
  $puppet_passenger_doc_root = '/etc/puppet/rack/public'

  # FOREMAN #
  $foreman_repo              = {
                                 'url' => 'https://github.com/theforeman/foreman.git -b 1.6-stable',
                                 'tag' => '1.6.1',
                               }
  $foreman_user              = 'foreman'
  $foreman_user_home         = '/usr/share/foreman'
  $foreman_settings          = {
                                 ':unattended'            => false,
                                 ':login'                 => true,
                                 ':require_ssl'           => true,
                                 ':locations_enabled'     => false,
                                 ':organizations_enabled' => false,
                                 ':support_jsonp'         => false,
                               }
  $foreman_default_password  = 'changeme'
  $foreman_db_adapter        = 'sqlite3'
  $foreman_db_host           = 'localhost'
  $foreman_db_name           = 'foreman'
  $foreman_db_pool           = '25'
  $foreman_db_timeout        = '5000'
  $foreman_db_user           = 'foreman'
  $foreman_vhost_server_name = $::fqdn
  $foreman_url               = "https://${::fqdn}"

  # SMART PROXY #
  $smartp_repo              = {
                                'url' => 'https://github.com/theforeman/smart-proxy.git -b 1.6-stable',
                                'tag' => '1.6.1',
                              }
  $smartp_user              = 'smartproxy'
  $smartp_user_home         = '/usr/share/smartproxy'
  $smartp_port              = '8443'
  $smartp_vhost_server_name = $::fqdn
}
