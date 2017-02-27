class aptly (

  $user        = 'aptly',
  $group       = 'aptly',
  $path        = '/var/aptly',
  $api_bind    = '127.0.0.1:8080',
  $manage_repo = true,
  $api_vhost   = 'aptly-api.localdomain',
  $pkg_vhost   = 'aptly.localdomain',
  $ssl_cert,
  $ssl_key,

) {

  group { $group:
    ensure => 'present',
    system => true,
  }

  user { $user:
    ensure     => 'present',
    system     => true,
    gid        => $group,
    shell      => '/bin/bash',
    managehome => false,
    home       => $path,
    require    => Group[$group],
  }

  # Should we manage the upstream repo?
  if $manage_repo {
    apt::source { 'aptly':
      location => 'http://repo.aptly.info',
      release  => 'squeeze',
      repos    => 'main',
      key      => {
        id     => 'B6140515643C2AE155596690E083A3782A194991',
        server => 'keys.gnupg.net',
      },
      include  => {
        src => false,
        deb => true,
      },
      before   => Package['aptly'],
    }
  }

  package { 'aptly':
    ensure  => 'installed',
  }

  file { '/etc/init.d/aptly-api':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => "puppet:///modules/${module_name}/etc/init.d/aptly-api",
  }

  file { '/etc/aptly.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/aptly.conf.erb"),
    notify  => Service['aptly-api'],
  }

  file { '/etc/default/aptly-api':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/default.erb"),
    notify  => Service['aptly-api'],
  }

  service { 'aptly-api':
    enable  => true,
    ensure  => 'running',
    require => [
      File['/etc/init.d/aptly-api'],
      File['/etc/default/aptly-api'],
      File['/etc/aptly.conf'],
      Package['aptly'],
    ],
  }

  nginx::resource::upstream { 'aptly-api':
    members => [ 'localhost:8080' ],
  }

  nginx::resource::vhost { $api_vhost:
    ensure      => 'present',
    listen_port => 443,
    ssl_port    => 443,
    ssl         => true,
    ssl_cert    => $ssl_cert,
    ssl_key     => $ssl_key,
    www_root    => "$path/public",
  }

  nginx::resource::vhost { $pkg_vhost:
    ensure               => 'present',
    listen_port          => 4443,
    ssl_port             => 4443,
    ssl                  => true,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    www_root             => "$path/public",
    client_max_body_size => '0',
  }

  nginx::resource::location { 'aptly-api':
    ensure   => present,
    ssl      => true,
    ssl_only => true,
    vhost    => $vhost,
    location => '/api',
    proxy    => 'http://aptly-api',
  }

}
