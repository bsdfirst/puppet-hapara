class haproxy () inherits haproxy::params {

  package { 'haproxy':
    ensure => 'installed',
  }

  package { 'hatop':
    ensure => 'installed',
  }

  # Configurations abstracted into different files for readability.
  class { 'haproxy::config': }
  class { 'haproxy::maps': }

  # Add HTTP host mapping for haproxy statistics page.
  haproxy::host_to_backend { 'stats_dispatcher':
    public   => true,
    httphost => $stats_host,
    backend  => 'stats_dispatcher',
  }

  # Collect exported configurations from backend nodes in the same environment.
  Haproxy::Backend         <<| tag == "environment::${::environment}" |>>
  Haproxy::Redirect        <<| tag == "environment::${::environment}" |>>
  Haproxy::Path_to_backend <<| tag == "environment::${::environment}" |>>
  Haproxy::Host_to_backend <<| tag == "environment::${::environment}" |>>
  Haproxy::Server          <<| tag == "environment::${::environment}" |>>

  # Also support a virtual "any" environment to allow the configuration of a backend on all content routers.
  Haproxy::Backend         <<| tag == "environment::any" |>>
  Haproxy::Redirect        <<| tag == "environment::any" |>>
  Haproxy::Path_to_backend <<| tag == "environment::any" |>>
  Haproxy::Host_to_backend <<| tag == "environment::any" |>>
  Haproxy::Server          <<| tag == "environment::any" |>>

  # Collect any trusted IPs tagged for this environment and for the "any" environment.  Trusted IPs are able
  # to access any backends configured against the "internal" facing (i.e. private) frontend/vip.
  Haproxy::Trusted_ip <<| tag == "environment::${::environment}" |>>
  Haproxy::Trusted_ip <<| tag == "environment::any" |>>

  # Create log file directory.
  file { '/var/log/haproxy':
    ensure  => 'directory',
    owner   => 'syslog',
    group   => 'adm',
    mode    => '0755',
    require => Class['rsyslog'],
  }

  # Configure rsyslog to use separate log file in it's own directory.
  rsyslog::conf { 'haproxy':
    content  => template( "${module_name}/rsyslog.erb" ),
    priority => '49',
    require  => File['/var/log/haproxy'],
  }

  # Configure logrotation to be in line with the policy specified in hiera.
  logrotate::rotate { 'haproxy':
    patterns   => [ '/var/log/haproxy/haproxy.log', ],
    postrotate => 'invoke-rc.d rsyslog rotate >/dev/null 2>&1 || true',
    require    => [ Package['haproxy'], File[ '/var/log/haproxy' ], ],
  }

  # Remove log file created by package.
  file { '/var/log/haproxy.log':
    ensure  => 'absent',
    require => Rsyslog::Conf['haproxy']  # do after this so that rsyslog is no longer writing to file
  }

  # The HAproxy reload already pretests the config, but if it fails, it still returns
  # zero, so puppet doesn't return an error.  We pre-test the config separately to catch
  # this.  Hacky, but means puppet stays in a broken state if the config is borked rather
  # than failing on the first run, then looking happy from that point forward (as a service
  # reload is not called until the haproxy.cfg file is touched again).
  exec { 'test_haproxy_config':
    command     => '/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg',  # re-run the test if the "unless" validation fails so puppet shows the validation output
    unless      => '/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg',  # this will run EVERY puppet run
    logoutput   => true,  # show the output of the failed validation
    require     => Service['haproxy'],  # make sure this runs after all config files in place
  }

  # Use reload rather than restart on config changes for zero downtime.
  service { 'haproxy':
    ensure  => 'running',
    enable  => true,
    require => Concat['/etc/haproxy/haproxy.cfg'],
    restart => $::os['distro']['codename'] ? { 'trusty' => 'service haproxy reload', default => 'systemctl reload haproxy' },
  }

}
