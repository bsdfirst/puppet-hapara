class retrypuppet() {

  file { '/usr/local/bin/retrypuppet':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => "puppet:///modules/${module_name}/usr/local/bin/retrypuppet",
  }

}
