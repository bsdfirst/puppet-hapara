define cron::job (

  # If set to false, the job will be commented out but the cron.d file will still be created.
  $enabled = true,

  # PATH variable set in the cron file.
  $path = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',

  # MAILTO variable set in the cron file.
  $email_dest = hiera( 'cron::job::email_dest', undef ),

  # Cron formatted time specifier.
  $timespec,

  # User the cron job should run as.
  $user = 'root',

  # If set to true, the command specified will be preceded by the slackron command for
  # reporting to slack.  This will catch all run output.  Any runtime error in the slackron
  # command would still be directed to $email_dest unless silent is also set.
  #$slackron = hiera( 'cron::job::slackron', false ),
  $slackron = true,

  # The command to execute.
  $command,

  # Direct cmd stdout and stderr to /dev/null (does not affect slackron command but does
  # mean that any errors output by slackron itself (if used) are swallowed.
  $silent = hiera( 'cron::job::silent', false ),

) {

  file { "/etc/cron.d/${name}":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( "${module_name}/cron-job.erb" ),
    require => Class['slackron'],
  }

}
