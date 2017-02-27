class hosts {

  file { '/etc/hosts':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( "${module_name}/hosts.erb" ),
  }

}
