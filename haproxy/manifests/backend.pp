define haproxy::backend (

  # Description of the backend added to the config file and stats interface as a comment.
  $description = '',

  # Allow the user to define the check to be used (will be prepended with 'option httpchk').
  $check = undef,

  # Any additional lines that should be added to the backend definition.
  $options = [],

  # Should this backend require authentication (accepts a group name from the "from_hiera" userlist).
  $authgroup = undef,

) {

  concat::fragment { "haproxy_backend_${name}":
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "\n## %s\nbackend %s\n", $description, $name ),
    order   => "70_backends_${name}_00",
  }

  concat::fragment { "haproxy_backend_${name}_description":
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "  description [BACKEND] %s\n", $description ),
    order   => "70_backends_${name}_10",
  }

  if $authgroup {
    concat::fragment { "haproxy_backend_${name}_auth":
      target  => '/etc/haproxy/haproxy.cfg',
      content => join( suffix( prefix( [
                   "acl hiera_auth_${name} http_auth_group(from_hiera) ${authgroup}",
                   "http-request auth unless hiera_auth_${name}", ],
                 '  ' ), "\n" ), '' ),
      order   => "70_backends_${name}_11",
    }
  }

  if $check {
    concat::fragment { "haproxy_backend_${name}_check":
      target  => '/etc/haproxy/haproxy.cfg',
      content => sprintf( "  option httpchk %s\n", $check ),
      order   => "70_backends_${name}_20",
    }
  }

  if size( $options ) > 0 {
    concat::fragment { "haproxy_backend_${name}_options":
      target  => '/etc/haproxy/haproxy.cfg',
      content => sprintf( "%s\n", join( prefix( $options, '  ' ), "\n" ) ),
      order   => "70_backends_${name}_30",
    }
  }

}
