define backup::job (

  # Should the backup run.
  $enabled = true,

  # What time should the backup run (in cron format - UTC).
  $cron = '00 00 * * *',

  # Should we halt the instance prior to the snapshot.
  $halt = false,

  # Address to email error output.
  $email_dest,

  # Should we try to send output to Slack?
  $slack = false,

  # How many days of backups should we retain.
  $retain = 365,

  # Command to run prior to running a backup (backup
  # will only execute if the command returns zero).
  $onlyif = undef,

) {

  if $::dmi['manufacturer'] != 'Google' {
    fail( 'We only support Google snapshot based backups.' )
  }

  # Export the cron job resource so we can realise it on the backup server.
  @@file { "/etc/cron.d/backup_${name}":
    ensure  => $enabled ? { true => 'present', false => 'absent' },
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( 'backup/cron-job.erb' ),
    tag     => 'backup',   # tag the resource so we can collect it on the backup server
  }

}
