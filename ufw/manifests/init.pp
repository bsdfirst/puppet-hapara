class ufw {

  # We don't use UFW, so remove to avoid confusion.
  package { 'ufw':
    ensure => 'purged',
  }

}
