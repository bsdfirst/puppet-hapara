define haproxy::path_to_backend (

  # Apply to the public facing frontend?
  $public = false,

  # Apply to the inward facing frontend?
  $internal = false,

  # Request path to match and route to backend.
  $path,

  # Which backend should matched traffic be sent to.
  $backend,

) {

  $_public = str2bool( $public )
  $_internal = str2bool( $internal )

  validate_bool( $_public )
  validate_bool( $_internal )

  if $_public {
    concat::fragment { "pub_path_to_backend_${name}":
      target  => "/etc/haproxy/pub_path_to_backend.map",
      content => "${path} ${backend}\n",
      order   => '10',
    }
  }

  if $_internal {
    concat::fragment { "int_path_to_backend_${name}":
      target  => "/etc/haproxy/int_path_to_backend.map",
      content => "${path} ${backend}\n",
      order   => '10',
    }
  }

}
