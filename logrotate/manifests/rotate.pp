define logrotate::rotate (

  # Require an array of patterns to match log names against.
  $patterns,

  # How often should we rotate (hourly|daily|weekly|monthly|yearly).
  $rotate = hiera( 'logrotate::rotate::rotate', 'daily' ),

  # What is the maximum size a log file should be permitted to grow to before forcing a rotation prior to $rotate.
  $maxsize = hiera( 'logrotate::rotate::maxsize', '100G' ),

  # How many rotations should we retain.
  $retention = hiera( 'logrotate::rotate::retention', 7 ),

  # Should we execute any command after the rotation.  (Will silence stdout and stderr.)
  $postrotate = undef,

) {

  # Validate input.
  validate_string( $name )
  validate_array( $patterns )
  validate_re( $rotate, '^(hourly|daily|weekly|monthly|yearly)$' )
  validate_string( $maxsize )
  validate_integer( $retention )

  file { "/etc/logrotate.d/${name}":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/logrotate.d.conf.erb"),
    require => Package['logrotate'],
  }

}
