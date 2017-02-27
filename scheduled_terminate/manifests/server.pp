class scheduled_terminate::server (
) {

  # Start/top script called from cron.
  file { '/usr/local/bin/gce_scheduled_terminate':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => "puppet:///modules/${module_name}/usr/local/bin/gce_scheduled_terminate",
  }

}
