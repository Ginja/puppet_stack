class puppet_stack::dependencies {
  case $::osfamily {
    'RedHat': {
      class { 'puppet_stack::dependencies::generic': }
      -> class { 'puppet_stack::dependencies::rhel': }
      contain 'puppet_stack::dependencies::generic'
      contain 'puppet_stack::dependencies::rhel'
    }
    'Debian': { fail('This module does not support your OS at this time.') } # Plan is to eventually support this
    default:  { fail('This module does not support your OS at this time.') }
  }
}
