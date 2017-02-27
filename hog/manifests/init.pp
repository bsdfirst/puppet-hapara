class hog () {

  # Multitail log tailing tool.
  file { '/usr/local/bin/hog':
    ensure => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => "puppet:///modules/${module_name}/usr/local/bin/hog",
    require => Class['profile::basebuild'],  # script requires multitail package
  }

}
