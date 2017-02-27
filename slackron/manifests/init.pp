class slackron() {

  file { '/usr/local/bin/slackron':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => "puppet:///modules/${module_name}/usr/local/bin/slackron",
  }

}
