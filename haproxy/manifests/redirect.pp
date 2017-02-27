define haproxy::redirect (

  # Apply to the public facing frontend?
  $public = false,

  # Apply to the inward facing frontend?
  $internal = false,

  # Use 301 or 302?
  $code = '302',

  # When URI matches, issue redirect to location.
  $uri,
  $location,

) {

  $_public = str2bool( $public )
  $_internal = str2bool( $internal )

  validate_re( $code, '^(301|302)$' )
  validate_bool( $_public )
  validate_bool( $_internal )

  if $_public {
    concat::fragment { "pub_redirect_${code}_${name}":
      target  => "/etc/haproxy/pub_redirect_${code}.map",
      content => "${uri} ${location}\n",
      order   => '10',
    }
  }

  if $_internal {
    concat::fragment { "int_redirect_${code}_${name}":
      target  => "/etc/haproxy/int_redirect_${code}.map",
      content => "${uri} ${location}\n",
      order   => '10',
    }
  }

}
