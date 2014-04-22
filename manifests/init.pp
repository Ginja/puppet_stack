class puppet_stack (
  $ruby_vers,
  $passenger_vers,
  $apache_user               = $::puppet_stack::params::apache_user,
  $http_dir                  = $::puppet_stack::params::http_dir,
  $rvm_prefix                = $::puppet_stack::params::rvm_prefix,
  $bundler_vers              = $::puppet_stack::params::bundler_vers,
  $rack_vers                 = $::puppet_stack::params::rack_vers,
  $global_passenger_options  = {},
  $puppet                    = true,
  $puppet_role               = $::puppet_stack::params::puppet_role,
  $cert_name                 = $::puppet_stack::params::cert_name,
  $ca_server                 = undef,
  $autosign_entries          = [],
  $site_pp_entries           = $::puppet_stack::params::site_pp_entries,
  $catalog_cert_autosign     = false,
  $conf_main                 = {}, # Default value comes from puppet.pp
  $conf_agent                = {}, # Default value comes from puppet.pp
  $conf_master               = {}, # Default value comes from puppet.pp
  $conf_envs                 = [],
  $puppet_vhost_options      = {},
  $puppet_ssl_cert           = '', # Default value comes from puppet.pp
  $puppet_ssl_key            = '', # Default value comes from puppet.pp
  $puppet_ssl_chain          = '', # Default value comes from puppet.pp
  $puppet_ssl_ca             = '', # Default value comes from puppet.pp
  $puppet_ssl_ca_revoc       = '', # Default value comes from puppet.pp
  $puppet_passenger_app_root = $::puppet_stack::params::puppet_passenger_app_root,
  $puppet_passenger_doc_root = $::puppet_stack::params::puppet_passenger_doc_root,
  $use_foreman_as_an_enc     = false,
  $upload_facts_to_foreman   = false,
  $foreman_url               = $::puppet_stack::params::foreman_url,
  $report_to_foreman         = false,
  $foreman                   = true,
  $foreman_repo              = $::puppet_stack::params::foreman_repo,
  $foreman_user              = $::puppet_stack::params::foreman_user,
  $foreman_user_home         = $::puppet_stack::params::foreman_user_home,
  $foreman_app_dir           = '', # Default value comes from foreman.pp
  $foreman_settings          = $::puppet_stack::params::foreman_settings,
  $foreman_db_adapter        = $::puppet_stack::params::foreman_db_adapter,
  $foreman_db_host           = $::puppet_stack::params::foreman_db_host,
  $foreman_db_pool           = $::puppet_stack::params::foreman_db_pool,
  $foreman_db_timeout        = $::puppet_stack::params::foreman_db_timeout,
  $foreman_db_name           = $::puppet_stack::params::foreman_db_name,
  $foreman_db_user           = $::puppet_stack::params::foreman_db_user,
  $foreman_db_password       = undef,
  $foreman_db_config         = [], # Default value comes from foreman.pp
  $foreman_vhost_options     = {},
  $foreman_vhost_server_name = $::puppet_stack::params::foreman_vhost_server_name,
  $foreman_ssl_cert          = '', # Default value comes from foreman.pp
  $foreman_ssl_key           = '', # Default value comes from foreman.pp
  $foreman_ssl_ca            = '', # Default value comes from foreman.pp
  $smartproxy                = true,
  $smartp_repo               = $::puppet_stack::params::smartp_repo,
  $smartp_user               = $::puppet_stack::params::smartp_user,
  $smartp_user_home          = $::puppet_stack::params::smartp_user_home,
  $smartp_port               = $::puppet_stack::params::smartp_port,
  $smartp_app_dir            = '', # Default value comes from smartproxy.pp
  $smartp_log_file           = '', # Default value comes from smartproxy.pp
  $smartp_settings           = {}, # Default value comes from smartproxy.pp
  $smartp_vhost_options      = {},
  $smartp_vhost_server_name  = $::puppet_stack::params::smartp_vhost_server_name,
  $smartp_ssl_cert           = '', # Default value comes from smartproxy.pp
  $smartp_ssl_key            = '', # Default value comes from smartproxy.pp
  $smartp_ssl_ca             = '', # Default value comes from smartproxy.pp
) inherits puppet_stack::params {
  validate_re($ruby_vers, 'ruby-\d[.]\d[.]\d-p\d+', 'The ruby_vers parameter did not match a valid Ruby version (ex: \'ruby-2.0.0-p451\')')
  validate_re($passenger_vers, '\d[.]\d[.]\d+', 'The passenger_vers parameter must be numerical (ex: \'4.0.40\')')
  validate_string($apache_user)
  validate_string($http_dir)
  validate_string($rvm_prefix)
  validate_string($bundler_vers)
  validate_string($rack_vers)
  validate_hash($global_passenger_options)
  # PUPPET #
  validate_bool($puppet)
  validate_re($puppet_role, ['^aio$', '^catalog$', '^ca$'], 'The puppet_role parameter did not match one of these values: "aio", "catalog", "ca"')
  validate_string($cert_name)
  if ($puppet_role == 'catalog') {
    validate_string($ca_server)
    # validate_string DOES NOT catch undef, like its documentation says it does
    # https://github.com/puppetlabs/puppetlabs-stdlib
    if ($ca_server == undef) {
      fail('The ca_server parameter cannot be left undefined when puppet_role is set to catalog')
    }
  }
  validate_array($autosign_entries)
  validate_array($site_pp_entries)
  validate_bool($catalog_cert_autosign)
  validate_hash($conf_main)
  validate_hash($conf_agent)
  validate_hash($conf_master)
  validate_array($conf_envs)
  validate_hash($puppet_vhost_options)
  validate_string($puppet_ssl_cert)    
  validate_string($puppet_ssl_key)
  validate_string($puppet_ssl_chain)
  validate_string($puppet_ssl_ca)
  validate_string($puppet_ssl_ca_revoc)
  validate_string($puppet_passenger_app_root)
  validate_string($puppet_passenger_doc_root)
  validate_bool($use_foreman_as_an_enc)
  validate_bool($upload_facts_to_foreman)
  validate_re($foreman_url, '^(http:\/\/|https:\/\/).*', "The foreman_url parameter needs to start with either http:// or https://")
  validate_bool($report_to_foreman)
  # FOREMAN #
  validate_bool($foreman)
  validate_string($foreman_repo)
  validate_string($foreman_user)
  validate_string($foreman_user_home)
  validate_string($foreman_app_dir)
  validate_hash($foreman_settings)
  validate_re($foreman_db_adapter, ['^postgresql$', '^sqlite3$'], 'The foreman_db_type parameter did not match one of these values: "postgresql", "sqlite3"')
  validate_string($foreman_db_host)
  validate_string($foreman_db_pool)
  validate_string($foreman_db_timeout)
  validate_string($foreman_db_name)
  if ($foreman_db_adapter == 'postgresql') {
    validate_string($foreman_db_user)
    validate_string($foreman_db_password)
    if ($foreman_db_password == undef) {
      fail('The foreman_db_password parameter cannot be left undefined when foreman_db_adapter is set to postgresql')
    }
  }
  validate_array($foreman_db_config)
  validate_hash($foreman_vhost_options)
  validate_string($foreman_ssl_cert)
  validate_string($foreman_ssl_key)
  validate_string($foreman_ssl_ca)
  # SMART-PROXY #
  validate_bool($smartproxy)
  validate_string($smartp_repo)
  validate_string($smartp_user)
  validate_string($smartp_user_home)
  validate_string($smartp_port)
  validate_string($smartp_app_dir)
  validate_string($smartp_vhost_server_name)
  validate_string($smartp_ssl_cert)
  validate_string($smartp_ssl_key)
  validate_string($smartp_ssl_ca)
  validate_hash($smartp_settings)
  validate_hash($smartp_vhost_options)
  if ($upload_facts_to_foreman == true)
  and ($foreman == false)
  and ($foreman_url == "https://${::fqdn}")
  and ($puppet_role != 'ca') {
    warning("You've specified to upload facts to the foreman, yet your foremal_url is pointing at this server. This is highly irregular. To turn this off set upload_facts_to_foreman to false.")
  }

  # MAIN #
  require puppet_stack::dependencies

  if ($puppet == true) {
    Class['puppet_stack::dependencies']
    -> class { 'puppet_stack::puppet': }
  }

  if ($foreman == true) {
    Class['puppet_stack::dependencies']
    -> class { 'puppet_stack::foreman': }
  }

  if ($smartproxy == true) {
    Class['puppet_stack::dependencies']
    -> class { 'puppet_stack::smartproxy': }
  }
}
