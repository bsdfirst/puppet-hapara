define rsyslog::conf (

  $content,
  $priority,

) {

  file { "/etc/rsyslog.d/${priority}-${name}.conf":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n${content}",
    notify  => Exec['reload_rsyslog'],
    require => Class['rsyslog'],
  }

  exec { 'reload_rsyslog':
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    command     => 'invoke-rc.d rsyslog restart',
    refreshonly => true,
    require     => Class['rsyslog'],
  }

}
