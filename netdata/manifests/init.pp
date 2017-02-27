class netdata {

  package { 'netdata':
    ensure => 'installed',
  }

  group { 'netdata':
    ensure => 'present',
    system => true,
  }

  user { 'netdata':
    ensure     => 'present',
    system     => true,
    gid        => 'netdata',
    home       => '/var/cache/netdata',
    managehome => false,
    shell      => '/usr/sbin/nologin',
    require    => Package['netdata'],   # package creates the home directory
  }

  file { '/etc/init/netdata.conf':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => "puppet:///modules/${module_name}/etc/init/netdata.conf",
    notify => Service['netdata'],
  }

  file { '/lib/systemd/system/netdata.service':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => "puppet:///modules/${module_name}/lib/systemd/system/netdata.service",
    notify => Service['netdata'],
  }

  file { '/etc/netdata/':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    recurse => true,
    purge   => true,
    force   => true,
    source  => "puppet:///modules/${module_name}/etc/netdata/",
    notify  => Service['netdata'],
  }

  ## We run netdata as a normal user, to have access to the required system calls,
  ## apps.plugin needs to run as root.  The apps.plugin binary is hard-coded to perform
  ## data collection.  It doesn't accept instruction from the netdata daemon to perform
  ## any tasks, so this is a safe as it can be.
  file { '/usr/lib/x86_64-linux-gnu/netdata/plugins.d/apps.plugin':
    owner => 'root',
    group => 'root',
    mode  => '4755',
  }

  ## Log directory is installed as root by the netdata package.
  file { '/var/log/netdata':
    owner   => 'netdata',
    group   => 'netdata',
    mode    => '0644',
    recurse => true,
  }

  ## Configure log rotation.
  file { '/etc/logrotate.d/netdata':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/etc/logrotate.d/netdata",
  }

  service { 'netdata':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['netdata'],
      User['netdata'],
      Group['netdata'],
      File['/etc/init/netdata.conf'],
      File['/etc/netdata/'],
      File['/usr/lib/x86_64-linux-gnu/netdata/plugins.d/apps.plugin'],
      File['/var/log/netdata'],
    ],
  }

}
