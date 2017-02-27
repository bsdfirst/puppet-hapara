define haproxy::trusted_ip (

  # Array of IP addresses to add to the trusted list.
  $ips,

  # Comment line to include in file (typically hostname).
  $comment,

) {

  # We expect IPs to be an array.
  validate_array( $ips )

  # We use the comment programmatically for ordering so valid characters are limited.
  validate_re( $comment, '[a-zA-Z0-9_.-]+' )

  concat::fragment { "trusted_ips_${comment}_comment":
    target  => '/etc/haproxy/trusted_ips',
    content => "\n# ${comment}\n",
    order   => "20_${comment}_10",
  }

  $ips.each | $ip | {
    concat::fragment { "trusted_ips_${comment}_${ip}":
      target  => '/etc/haproxy/trusted_ips',
      content => "${ip}/32\n",
      order   => "20_${comment}_20",
    }
  }

}
