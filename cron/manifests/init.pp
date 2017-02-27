class cron (

  $purge_crond = false,

) {

  # Ensure cron is installed.
  package { 'cron':
    ensure => 'installed',
  }

  # Ensure cron is running.
  service { 'cron':
    ensure  => 'running',
    enable  => true,
    require => Package['cron'],
  }

  # Purge any files in cron.d that were not created by puppet if configured to do so.
  if ( $purge_crond ) {
    file { '/etc/cron.d/':
      purge   => true,
      recurse => true,
      force   => true,
    }
  }

}
