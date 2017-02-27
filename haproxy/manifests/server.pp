define haproxy::server (

  # Which backend should the server be added to.
  $backend,

  # Hostname/listening port of the server to add (we require IP address)
  # as well as host as google will not result the IP address of an instance
  # that is not running; this can cause it to become impossible to reload
  # HAproxy configurations when backends are down.
  $host,
  $port,
  $ipaddr,

  # Any additional options to be added after the server definition.
  $options = '',

) {

  unless defined( Haproxy::Backend[$backend] ) {
    fail( "Backend ${backend} is not defined.  Cannot add server ${name} to nonexistent backend." )
  }

  concat::fragment { "haproxy_server_${backend}_${name}":
    target  => '/etc/haproxy/haproxy.cfg',
    content => sprintf( "  server %s %s:%i check observe layer4%s\n", $host, $ipaddr, $port, size( $options ) ? { 0 => '', default => " ${options}" } ),
    order   => "70_backends_${backend}_80",
  }

}
