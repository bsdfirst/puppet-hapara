class puppetagent (

  # Should the puppet agent process run.
  $enable = true,

  # Should we run in noop by default.
  $noop = false,

  # How often should the puppet agent poll (default to low value so new hosts reconfigure quickly).
  $runinterval = '1m',

  # What puppet server should the agent point too?
  $server,

) {

  # Determine environment based on hostname if possible, otherwise make no change.
  if $::hostname =~ /^([a-z])/ {
    $derived_env = $1 ? {
      'd'     => 'dev',
      't'     => 'test',
      'p'     => 'prod',
      default => $::environment,
    }
  } else {
    $derived_env = $::environment
  }

  ini_setting { 'puppet_agent_conf_environent':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'environment',
    value   => $derived_env,
    before  => Service['puppet'],
    notify  => Service['puppet'],
  }

  ini_setting { 'puppet_agent_conf_runinterval':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'runinterval',
    value   => $runinterval,
    before  => Service['puppet'],
    notify  => Service['puppet'],
  }

  ini_setting { 'puppet_agent_conf_splay':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'splay',
    value   => 'true',
    before  => Service['puppet'],
    notify  => Service['puppet'],
  }

  ini_setting { 'puppet_agent_conf_noop':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'noop',
    value   => "$noop",   # must quote to cause cast to string, otherwise doesn't behave as expected
    before  => Service['puppet'],
    notify  => Service['puppet'],
  }

  ini_setting { 'puppet_agent_conf_server':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'server',
    value   => $server,
    before  => Service['puppet'],
    notify  => Service['puppet'],
  }

  service { 'puppet':
    ensure => $enable ? { true => 'running', false => 'stopped', },
    enable => $enable,
  }

  # We are not using the mCollective component that is installed and started by default.
  service { 'mcollective':
    ensure => 'stopped',
    enable => false,
  }

  # We are not current using pxp-agent so stop it for now.
  service { 'pxp-agent':
    ensure => 'stopped',
    enable => false,
  }

  file { '/etc/profile.d/Z99-puppet_path.sh':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => "puppet:///modules/${module_name}/etc/profile.d/Z99-puppet_path.sh",
  }

}
