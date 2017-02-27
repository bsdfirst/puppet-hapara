class salt::minion (

  ## The hostname of the salt master we should connect to.
  $master,

  ## The path that the minion should run under.
  $minion_path = '/opt/puppetlabs/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',

) {

  package { 'salt-minion':
    ensure => 'installed',
  }

  ## Create directory structure for certificates (created by package,
  ## but we can force the service to run first otherwise we end up
  ## with a loop with our notify statement).
  file { '/etc/salt':
    ensure => 'directory',
    mode   => '0755',
  } ->
  file { '/etc/salt/pki':
    ensure => 'directory',
    mode   => '0755',
  } ->
  file { '/etc/salt/pki/minion':
    ensure => 'directory',
    mode   => '0700',
  }

  ## Use the puppet certificate.
  file { '/etc/salt/pki/minion/minion.pem':
    ensure  => 'link',
    target  => "/etc/puppetlabs/puppet/ssl/private_keys/${::fqdn}.pem",
    notify  => Service['salt-minion'],
    require => [ Package['salt-minion'], File['/etc/salt/pki/minion'], ],
  }

  ## Use the puppet public key.
  file { '/etc/salt/pki/minion/minion.pub':
    ensure  => 'link',
    target  => "/etc/puppetlabs/puppet/ssl/public_keys/${::fqdn}.pem",
    notify  => Service['salt-minion'],
    require => [ Package['salt-minion'], File['/etc/salt/pki/minion'], ],
  }

  # Default for all file types.
  File {
    ensure => 'present',
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
  }

  ## Export the puppet public key to be deployed on the salt master.
  @@file { "/etc/salt/pki/master/minions/${::fqdn}":
    content => $::puppet_pubkey,
    tag     => 'salt_minion_pubkey',
    require => Package['salt-master'],
  }

  ## Add all puppet facts into Salt as grains.
  file { '/etc/salt/grains':
    content => template( 'salt/grains.erb' ),
    require => Package['salt-minion'],
  }

  ## Reload salt grain cache if custom grains changed.
  exec { 'reload_salt_grains':
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    command     => 'salt-call saltutil.sync_grains',
    refreshonly => true,
    subscribe   => File['/etc/salt/grains'],
  }

  ## Configure which master to point to.
  file { '/etc/salt/minion.d/master.conf':
    content => "### FILE MANAGED BY PUPPET ###\n\n\nmaster: ${master}\n",
    notify  => Service['salt-minion'],
    require => Package['salt-minion'],
  }

  ## Configure minion id.
  file { '/etc/salt/minion_id':
    content => "${::fqdn}\n",
    notify  => Service['salt-minion'],
    require => Package['salt-minion'],
  }

  ## Configure the minion to use sha256 hashing rather than the md5 default.
  file { '/etc/salt/minion.d/hash_type.conf':
    content => "### FILE MANAGED BY PUPPET ###\n\n\nhash_type: sha256\n",
    notify  => Service['salt-minion'],
    require => Package['salt-minion'],
  }

  ## Configure a fixed path, otherwise salt inherits a path from puppet (doesn't include /opt/puppetlabs) - upstart/trusty.
  file { '/etc/default/salt-minion':
    content => "### FILE MANAGED BY PUPPET\n\n\nPATH=${minion_path}\n",
    notify  => Service['salt-minion'],
    require => Package['salt-minion'],
  }

  ## Configure a fixed path, otherwise salt inherits a path from puppet (doesn't include /opt/puppetlabs) - upstart/trusty.
  if $::os['distro']['codename'] == 'xenial' {

    file { '/etc/systemd/system/salt-minion.service.d':
      ensure => 'directory',
    } ->
    file { '/etc/systemd/system/salt-minion.service.d/override.conf':
      content => "### FILE MANAGED BY PUPPET\n\n\n[Service]\nEnvironment=\"PATH=$minion_path\"\n",
      notify  => Service['salt-minion'],
      require => Package['salt-minion'],
    }

    exec { 'systemctl_daemon_reload':
      path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      command     => 'systemctl daemon-reload',
      refreshonly => true,
      subscribe   => File['/etc/systemd/system/salt-minion.service.d/override.conf'],
      before      => Service['salt-minion'],
    }

  }

  ## As we re-use the puppet certificates for salt, there is a race condition where the client can attempt
  ## to start prior the salt-master having the clients public cert (via an exported resource).  In this case
  ## the minion immediately dies.  If this is a prod node, and thus puppet is set to noop by default, then
  ## the salt minion will never end up starting.  This works around that issue.  There is no scenario where
  ## the salt minion should be disabled on a node so this is considered safe.
  file { '/etc/cron.d/salt-minion-running':
    content => template( 'salt/salt-minion-running.cron.erb' ),
    require => [
                 Package['salt-minion'],
                 File['/etc/salt/minion.d/master.conf'],
                 File['/etc/default/salt-minion'],
                 Service['salt-minion'],  # make sure we put the cron file in place AFTER the first run that generates the certs
               ],
  }

  service { 'salt-minion':
    ensure  => 'running',
    enable  => true,
    require => [ Package['salt-minion'], File['/etc/salt/minion.d/master.conf'], ],
  }

}
