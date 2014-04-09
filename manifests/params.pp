class puppet_stack::params {
  # Because we use contain
  validate_re($::puppetversion, '^3[.]4[.]\d+', "The puppet_stack module requires a Puppet version of 3.4.0+ - version: ${::puppetversion}")
  # Because 1.8.* should not be used anymore. They're EOL!
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

  # PUPPET MASTER #
  $puppet_role               = 'aio'
  $cert_name                 = $::fqdn
  $site_pp_entries           = [ 'node default {}' ]
  $puppet_ssl_ca_revoc       = '/var/lib/puppet/ssl/ca/ca_crl.pem'
  $puppet_passenger_app_root = '/etc/puppet/rack'
  $puppet_passenger_doc_root = '/etc/puppet/rack/public'

  # FOREMAN #
  $foreman_repo              = 'https://github.com/theforeman/foreman.git -b 1.4-stable'
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
  $foreman_db_adapter        = 'sqlite3'
  $foreman_db_host           = 'localhost'
  $foreman_db_name           = 'foreman'
  $foreman_db_user           = 'foreman'
  $foreman_vhost_server_name = $::fqdn
  $foreman_url               = "https://${::fqdn}"

  # SMART PROXY #
  $smartp_repo              = 'https://github.com/theforeman/smart-proxy.git -b develop'
  $smartp_user              = 'smartproxy'
  $smartp_user_home         = '/usr/share/smartproxy'
  $smartp_port              = '8443'
  $smartp_vhost_server_name = $::fqdn
}
