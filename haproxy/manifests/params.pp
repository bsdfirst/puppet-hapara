class haproxy::params (

  # HAproxy timeouts (https://cbonte.github.io/haproxy-dconv/configuration-1.6.html#4-timeout).
  $timeout_check      = '2s',
  $timeout_connect    = '5s',
  $timeout_request    = '20s',
  $timeout_queue      = '10s',
  $timeout_client     = '1m',
  $timeout_server     = '1m',
  $timeout_client_fin = '10s',

  # Maximum connections that an individual instance supports.
  $maxconn = '15000',

  # Specify an email address that should be alerted when a backend status changed.
  $alert_email = undef,

  # SSL ciphers that are permitted for all SSL comms.
  $ciphers = 'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS',

  # Array of content routers in this environment (used for peers statement and stats routing).
  $servers,

  # Bind parameters for internal/external http and https frontends.
  $bind_pub_https,
  $bind_pub_http,
  $bind_int_https,
  $bind_int_http,

  # Hostname that should be routed to the itnernal stats backend.
  $stats_host  = "${::environment}-haproxy.localdomain",

  # Hash of HAproxy userlist sections.
  $userlists = {},

  # Array of IP addresses that should be considered as "local" sources.
  $trusted_ips = [],

  # Source IP addresses that should be denied access.
  $blacklist_nets = [],

  # MIME types that should be compressed if supported by the client.
  $comp_types = [ 'text/html', 'text/plain', 'text/css', ],

) {}
