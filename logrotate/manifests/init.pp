class logrotate () {

  # Ensure our compression tool of choice is installed.
  ensure_packages ( [ 'liblz4-tool' ] )

  # Ensure lograte is installed.
  package { 'logrotate':
    ensure  => 'installed',
    require => Package['liblz4-tool'],
  }

  # Switch logratote to hourly runs.
  file { '/etc/cron.daily/logrotate':
    ensure => 'absent',
  } ->
  file { '/etc/cron.hourly/logrotate':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => "puppet:///modules/${module_name}/etc/cron.hourly/logrotate",
    require => Package['logrotate'],
  }

  # Replace default rotations supplied in package so that our hiera rotate parameters are honoured.
  logrotate::rotate { 'rsyslog':
    patterns => [
      '/var/log/syslog',
      '/var/log/mail.info',
      '/var/log/mail.warn',
      '/var/log/mail.err',
      '/var/log/mail.log',
      '/var/log/daemon.log',
      '/var/log/kern.log',
      '/var/log/auth.log',
      '/var/log/user.log',
      '/var/log/lpr.log',
      '/var/log/cron.log',
      '/var/log/debug',
      '/var/log/messages',
    ],
    postrotate => 'kill -HUP $(cat /run/rsyslogd.pid)',
  }

}
