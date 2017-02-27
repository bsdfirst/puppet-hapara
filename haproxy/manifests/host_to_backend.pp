define haproxy::host_to_backend (

  # Apply to the public facing frontend?
  $public = false,

  # Apply to the inward facing frontend?
  $internal = false,

  # HTTP Host header to match and route to backend.
  $httphost,

  # Which backend should matched traffic be sent to.
  $backend,

) {

  $_public = str2bool( $public )
  $_internal = str2bool( $internal )

  validate_bool( $_public )
  validate_bool( $_internal )

  if $_public {
    concat::fragment { "pub_host_to_backend_${name}":
      target  => "/etc/haproxy/pub_host_to_backend.map",
      content => "${httphost} ${backend}\n",
      order   => '10',
    }
  }

  if $_internal {
    concat::fragment { "int_host_to_backend_${name}":
      target  => "/etc/haproxy/int_host_to_backend.map",
      content => "${httphost} ${backend}\n",
      order   => '10',
    }
  }

}
