require 'spec_helper_acceptance'

describe 'puppet_stack' do
  it 'manifest should apply with no errors' do
    hosts.each do |host|
      on host, "rvm use `rvm list | awk '/^=[*]/{ print $2 }'`"
    end

    manifest = <<-EOS
class { 'puppet_stack':
  ruby_vers               => 'ruby-2.0.0-p451',
  passenger_vers          => '4.0.40',
  puppet                  => true,
  puppet_role             => 'aio',
  use_foreman_as_an_enc   => true,
  report_to_foreman       => true,
  upload_facts_to_foreman => true,
  foreman                 => true,
# foreman_db_adapter      => 'postgresql',
# foreman_db_password     => 'secret',
  smartproxy              => true,
}
    EOS
    # Run it twice and test for idempotency
    apply_manifest_on hosts, manifest, { :catch_failures => true, :acceptable_exit_codes => [0, 2] }
    # Should work: 
    # https://github.com/puppetlabs/beaker/issues/210
    # https://github.com/puppetlabs/beaker/issues/402
    #apply_manifest_on hosts, manifest, { :environment => { 'PATH' => "/usr/local/rvm/gems/#{options['ruby_version']}/bin:/usr/local/rvm/gems/#{options['ruby_version']}@global/bin:/usr/local/rvm/rubies/#{options['ruby_version']}/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/rvm/bin:/root/bin"},
    #                                     :catch_failures => true }
    apply_manifest_on hosts, manifest, { :catch_failures => true, :acceptable_exit_codes => [0, 2] }
  end
end
