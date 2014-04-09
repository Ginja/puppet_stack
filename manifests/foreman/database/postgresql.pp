class puppet_stack::foreman::database::postgresql {
  $foreman_db_name     = $::puppet_stack::foreman_db_name
  $foreman_db_user     = $::puppet_stack::foreman_db_user
  $foreman_db_password = $::puppet_stack::foreman_db_password
  $foreman_db_host     = $::puppet_stack::foreman_db_host

  contain postgresql::server

  postgresql::server::db { $foreman_db_name:
    user     => $foreman_db_user,
    password => postgresql_password($foreman_db_user, $foreman_db_password),
  }
}
