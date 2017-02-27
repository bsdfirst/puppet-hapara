class thp (

  $enabled = true,

) {

  # We only bother to support systemd as that's all we need, so check we're not applied to trusty and below.
  if ( $::os['name'] == 'Ubuntu' ) and ( versioncmp( $::os['release']['major'], '16.04' ) >= 0 ) {

    # Make sure that the enabled flag is a boolean.
    validate_bool( $enabled )

    # Convert the bool into the value the kernel expects.
    $thp_param = $enabled ? {
      true  => 'always',
      false => 'never',
    }

    # Enable/disable on boot using systemd tmpfiles.d.
    file { '/etc/tmpfiles.d/puppet-thp.conf':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template( "${module_name}/puppet-thp.conf.erb" ),
    }

    # Also check at runtime and disable if required.
    exec { "transparent_hugepage_enabled":
      command => "/bin/echo ${thp_param} > /sys/kernel/mm/transparent_hugepage/enabled",
      unless  => "/bin/grep -q '\\[${thp_param}\\]' /sys/kernel/mm/transparent_hugepage/enabled",
    }

    exec { "transparent_hugepage_defrag":
      command => "/bin/echo ${thp_param} > /sys/kernel/mm/transparent_hugepage/defrag",
      unless  => "/bin/grep -q '\\[${thp_param}\\]' /sys/kernel/mm/transparent_hugepage/defrag",
    }


  } else {

    warn( 'Cannot manage THP for this OS version.' )

  }

}
