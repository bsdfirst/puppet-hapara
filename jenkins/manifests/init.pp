class jenkins () {

  package { 'jenkins':
    ensure => 'installed',
  }

  package { [ 'bison', 'ruby-dev', 'libsasl2-dev' ]:
    ensure => 'installed',
  }

  package { 'fpm':
    provider => 'gem',
  }

  file { '/etc/default/jenkins':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( "${module_name}/default.erb" ),
    require => Package['jenkins'],
    notify  => Service['jenkins'],
  }

  service { 'jenkins':
    enable  => true,
    ensure  => 'running',
    require => Package['jenkins'],
  }

}
