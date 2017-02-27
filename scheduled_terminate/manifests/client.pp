class scheduled_terminate::client (

  # Should this node be terminated overnight for cost savings (and restarted in the morning)?
  $enabled = false,

) {

  # Must be a boolean.
  validate_bool( $enabled )

  # Create the filesystem location that is checked by the terminate
  # script (terminate skipped unless this file is present on the target node).
  file { '/schedule_terminate':
    ensure => $enabled ? { true => 'present', default => 'absent' },
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
  }

}
