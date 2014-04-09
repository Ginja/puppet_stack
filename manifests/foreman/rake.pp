class puppet_stack::foreman::rake {
  $rails_env           = 'RAILS_ENV=production' # Not exposed
  $rvm_prefix          = $::puppet_stack::rvm_prefix
  $ruby_vers           = $::puppet_stack::ruby_vers
  $bundle_path         = "${rvm_prefix}/gems/${ruby_vers}/bin"
  $rake_db_migrate     = "${bundle_path}/bundle exec rake db:migrate ${rails_env}"
  $touch_migrate       = "/bin/echo ${ruby_vers} > vendor/.rake.migrate.complete"
  $rake_db_seed        = "${bundle_path}/bundle exec rake db:seed assets:precompile locale:pack ${rails_env}"
  $touch_seed          = "/bin/echo ${ruby_vers} > vendor/.rake.seed.complete"
  $foreman_user        = $::puppet_stack::foreman_user
  $foreman_user_home   = $::puppet_stack::foreman_user_home
  $foreman_app_dir     = $::puppet_stack::foreman::foreman_app_dir

  exec { "${rake_db_migrate} && ${touch_migrate}":
    user        => $foreman_user,
    environment => [ "HOME=${foreman_user_home}", ],
    cwd         => $foreman_app_dir,
    logoutput   => on_failure,
    creates     => "${foreman_app_dir}/vendor/.rake.migrate.complete",
    subscribe   => [ Exec['foreman_bundle_install'], File["${foreman_app_dir}/config/database.yml" ] ],
  }
  exec { "${rake_db_seed} && ${touch_seed}":
    user        => $foreman_user,
    environment => [ "HOME=${foreman_user_home}", ],
    cwd         => $foreman_app_dir,
    logoutput   => on_failure,
    creates     => "${foreman_app_dir}/vendor/.rake.seed.complete",
    subscribe   => [ Exec['foreman_bundle_install'], File["${foreman_app_dir}/config/database.yml" ] ],
    require     => Exec["${rake_db_migrate} && ${touch_migrate}"],
  }
}
