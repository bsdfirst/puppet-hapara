class haproxy::maps () inherits haproxy::params {

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

  concat { '/etc/haproxy/pub_redirect_301.map': }
  concat::fragment { 'pub_redirect_301_header':
    target  => '/etc/haproxy/pub_redirect_301.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/pub_redirect_302.map': }
  concat::fragment { 'pub_redirect_302_header':
    target  => '/etc/haproxy/pub_redirect_302.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/pub_path_to_backend.map': }
  concat::fragment { 'pub_path_to_backend_header':
    target  => '/etc/haproxy/pub_path_to_backend.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/pub_host_to_backend.map': }
  concat::fragment { 'pub_host_to_backend_header':
    target  => '/etc/haproxy/pub_host_to_backend.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/int_redirect_301.map': }
  concat::fragment { 'int_redirect_301_header':
    target  => '/etc/haproxy/int_redirect_301.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/int_redirect_302.map': }
  concat::fragment { 'int_redirect_302_header':
    target  => '/etc/haproxy/int_redirect_302.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/int_path_to_backend.map': }
  concat::fragment { 'int_path_to_backend_header':
    target  => '/etc/haproxy/int_path_to_backend.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/int_host_to_backend.map': }
  concat::fragment { 'int_host_to_backend_header':
    target  => '/etc/haproxy/int_host_to_backend.map',
    content => "### FILE MANAGED BY PUPPET ###\n\n\n",
    order   => '00',
  }

  concat { '/etc/haproxy/trusted_ips': }
  concat::fragment { 'trusted_ips_hiera':
    target  => '/etc/haproxy/trusted_ips',
    content => template( "${module_name}/trusted_ips.erb" ),
    order   => '10',
  }

  file { '/etc/haproxy/blacklist_nets':
    content => template( "${module_name}/blacklist_nets.erb" ),
  }

}
