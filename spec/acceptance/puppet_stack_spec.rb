require 'spec_helper_acceptance'

describe 'puppet_stack' do
  it 'should work with no errors' do
    pp = <<-EOS
class { 'puppet_stack':
  ruby_vers               => 'ruby-2.0.0-p451',
  passenger_vers          => '4.0.40',
  puppet                  => true,
  puppet_role             => 'aio',
  foreman                 => true,
  smartproxy              => true,
}
    EOS
    # Run it twice and test for idempotency
    apply_manifest(pp, :catch_failures => true )
    # Should work, https://github.com/puppetlabs/beaker/issues/210
    #apply_manifest pp, { :environment => {'PATH' => '/usr/local/rvm/gems/ruby-2.0.0-p451/bin:/usr/local/rvm/gems/ruby-2.0.0-p451@global/bin:/usr/local/rvm/gems/ruby-2.0.0-p451/bin:/usr/local/rvm/gems/ruby-2.0.0-p451@global/bin:/usr/local/rvm/rubies/ruby-2.0.0-p451/bin:/usr/bin:/opt/puppet-git-repos/hiera/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/local/rvm/bin' }, :catch_failures => true }
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
  end
end
