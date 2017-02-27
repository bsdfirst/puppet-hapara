class atop (

  $enable = true,
  $poll_interval = '600',

) {

  package { 'atop':
    ensure => 'installed',
  }

  # The cron module can be configured in hiera to purge all cron jobs puppet doesn't
  # know about.  The atop package installs a cron job.  We don't need to manage it's
  # content, but delcare it so that it doesn't get purged.
  file { '/etc/cron.d/atop':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['atop'],
  }

  file { '/etc/default/atop':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/defaults.erb"),
    require => Package['atop'],
    notify  => Service['atop'],
  }

  service { 'atop':
    ensure  => $enable ? { true => 'running', false => 'stopped', },
    enable  => $enable,
    require => [ Package['atop'], File['/etc/default/atop'], ],
  }

}
