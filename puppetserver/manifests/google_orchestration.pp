class puppetserver::google_orchestration () {

  file { '/usr/local/bin/gce_clean_certs':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => "puppet:///modules/${module_name}/usr/local/bin/gce_clean_certs",
  } ->

  cron::job { 'gce_clean_certs':
    path     => '/opt/puppetlabs/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin:/sbin:/bin',  # override default to include puppet
    timespec => '*/5 * * * *',
    command  => 'gce_clean_certs',
  }

}
