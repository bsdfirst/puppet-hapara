class mailer (

  # Should we use Sendgrid for all outbound mail?
  $use_sendgrid       = false,
  $sendgrid_relayhost = 'smtp.sendgrid.net',
  $sendgrid_relayport = '587',
  $sendgrid_user      = '',
  $sendgrid_pass      = '',

  # Should we use Google Apps for Business as a relay?
  $use_google_mta     = false,
  $google_user        = '',
  $google_pass        = '',

  # If we're not using sendgrid, allow relayhost to be passed from hiera.
  $relayhost = undef,

  # User that should receive email address to "root" with no domain part.
  $root_dest,

) {

  # Configure upstream relay.
  if ( $use_sendgrid and $relayhost ) or ( $use_sendgrid and $use_google_mta ) or ( $use_google_mta and $relayhost ) {
    fail( 'Only one of use_sendgrid, use_google_mta, or relayhost may be specified.' )
  } else {

    if $use_sendgrid {
      $actual_relayhost           = "[${sendgrid_relayhost}]:${sendgrid_relayport}"
      $smtp_sasl_auth_enable      = true
      $smtp_sasl_password_maps    = "static:${sendgrid_user}:${sendgrid_pass}"
      $smtp_sasl_security_options = 'noanonymous'
      $smtp_use_tls               = true
      $smtp_tls_security_level    = 'may'
      $extra_params               = {
        'header_size_limit' => '4096000',
      }
    } elsif $use_google_mta {
      $actual_relayhost           = '[smtp-relay.gmail.com]:587'
      $smtp_sasl_auth_enable      = true
      $smtp_sasl_password_maps    = "static:${google_user}:${google_pass}"
      $smtp_sasl_security_options = 'noanonymous'
      $smtp_use_tls               = true
      $smtp_tls_security_level    = 'may'
      $extra_params               = undef
    } elsif $relayhost {
      $actual_relayhost           = "[${relayhost}]"
      $smtp_sasl_auth_enable      = undef
      $smtp_sasl_password_maps    = undef
      $smtp_sasl_security_options = undef
      $smtp_use_tls               = undef
      $smtp_tls_security_level    = undef
      $extra_params               = undef
    }

  }

  package { 'libsasl2-modules':
    ensure => 'installed',
  }

  class { '::postfix::server':

    # The postfix module is designed to reload rather than restart on a config change, but this
    # won't work for a number of parameters such as bind address which require a restart so we
    # overwrite the restart command that the module uses.  (Which would typically be what puppet
    # would do by default anyway so we are really overriding the override.)
    service_restart => '/usr/sbin/service postfix restart',

    # Only relay for local machine (and only bind 127.0.0.1).  
    mynetworks_style => 'host',
    inet_interfaces  => 'localhost',
    submission       => true,

    # The layout of the postfix module changed significantly from around 3.x, this means
    # we must set the daemon_directory differently based on postfix version.  There is no
    # fact exposing postfix version, so we make a broad assumption based on os distribution.
    daemon_directory => $::os['distro']['codename'] ? { 'trusty' => '/usr/lib/postfix', 'xenial' => '/usr/lib/postfix/sbin' },

    # We use Sendgrid as a relay for all outbound mail.
    smtp_sasl_auth             => $smtp_sasl_auth_enable,
    smtp_sasl_password_maps    => $smtp_sasl_password_maps,
    smtp_sasl_security_options => $smtp_sasl_security_options,
    smtp_use_tls               => $smtp_use_tls,
    smtp_tls_security_level    => $smtp_tls_security_level,
    relayhost                  => $actual_relayhost,
    extra_main_parameters      => $extra_params,

    # Make sure we have the SASL libs before we try to install postfix.
    require => Package['libsasl2-modules'],

  }

  # We specify this directly in the config file, so we remove this file to avoid confusion.
  file { '/etc/mailname':
    ensure => 'absent',
  }

  file { '/etc/aliases':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/aliases.erb"),
    require => Class['::postfix::server'],
  }

  exec { 'newaliases':
    command     => '/usr/bin/newaliases',
    refreshonly => true,
    require     => [ Class['::postfix::server'], File['/etc/aliases'], ],
    subscribe   => File['/etc/aliases'],
  }

  package { 'mailutils':
    ensure  => 'installed',
    require => Class['::postfix::server'],
  }

}
