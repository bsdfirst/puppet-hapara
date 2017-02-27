class haproxy::config () inherits haproxy::params {

  Concat {
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Service['haproxy'],
    require => Package['haproxy'],
  }

  File {
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Service['haproxy'],
    require => Package['haproxy'],
  }

  concat { '/etc/haproxy/haproxy.cfg': }

  concat::fragment { 'haproxy_header':
    target  => '/etc/haproxy/haproxy.cfg',
    content => "### FILE MANAGED BY PUPPET ###\n",
    order   => '00',
  }

  concat::fragment { 'haproxy_global':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n\n%s", template( "${module_name}/global.erb" ) ),
    order   => '10_main_10',
  }

  concat::fragment { 'haproxy_mailers':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n%s", template( "${module_name}/mailers.erb" ) ),
    order   => '10_main_20',
  }

  concat::fragment { 'haproxy_peers':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n%s", template( "${module_name}/peers.erb" ) ),
    order   => '10_main_30',
  }

  concat::fragment { 'haproxy_defaults':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n\n%s", template( "${module_name}/defaults.erb" ) ),
    order   => '10_main_40',
  }

  concat::fragment { 'haproxy_users':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n\n%s", template( "${module_name}/users.erb" ) ),
    order   => '10_main_50',
  }

  concat::fragment { 'haproxy_stats':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n\n%s", template( "${module_name}/stats.erb" ) ),
    order   => '10_main_60',
  }

  concat::fragment { 'haproxy_frontends':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n\n%s", template( "${module_name}/frontends.erb" ) ),
    order   => '50_frontends_10',
  }

  concat::fragment { 'haproxy_backends':
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n\n\n%s", template( "${module_name}/backends.erb" ) ),
    order   => '69_backends_00',
  }

}
