class timezone (

  $timezone = 'Etc/UTC',

) {

  file { '/etc/timezone':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => "${timezone}\n",
  }

  exec { 'update_timezone':
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    command     => 'dpkg-reconfigure --frontend noninteractive tzdata',
    refreshonly => true,
    subscribe   => File['/etc/timezone'],
  }

}
