class puppetserver::hiera {

  # Note: this class is designed not to take paramters so that it can be
  # used to boostrap the hiera installation when building a puppetmaster.

  # Additionally, we use before/subscribe from the puppetserver class
  # rather than require/notify here for the same reason.

  class { 'hiera':
    logger         => 'console',
    merge_behavior => 'deeper',
    backends       => [ 'yaml', 'eyaml', ],  # puppetdb backend is also available, but breaks the hiera commandline and is not required
    eyaml          => true,
    eyaml_version  => 'installed',
    datadir        => '/etc/puppetlabs/code/hieradata',
    datadir_manage => true,
    hierarchy      => [
      '05_secure/%{::environment}',
      '10_hosts/%{trusted.certname}',
      '15_datacentres/%{::dmi.manufacturer}',
      '35_calling_class/%{calling_class}/%{::environment}',
      '35_calling_class/%{calling_class}/default',
      '40_calling_module/%{calling_module}/%{::environment}',
      '40_calling_module/%{calling_module}/default',
      '65_users/%{::environment}',
      '65_users/default',
      '99_globals/%{::environment}',
      '99_globals/default',
    ],
  }

}
