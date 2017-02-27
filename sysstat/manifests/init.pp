class sysstat (

  $enable = true,

) {

  package { 'sysstat':
    ensure => 'installed',
  }

  # The cron module can be configured in hiera to purge all cron jobs puppet doesn't
  # know about.  The sysstat package installs a cron job.  We don't need to manage it's
  # content, but delcare it so that it doesn't get purged.
  file { '/etc/cron.d/sysstat':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['sysstat'],
  }

  file { '/etc/default/sysstat':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/defaults.erb"),
    require => Package['sysstat'],
    notify  => Service['sysstat'],
  }

  service { 'sysstat':
    ensure  => $enable ? { true => 'running', false => 'stopped', },
    enable  => $enable,
    require => [ Package['sysstat'], File['/etc/default/sysstat'], ],
  }

}
