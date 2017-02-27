class salt::master {

  package { 'salt-master':
    ensure => 'installed',
  }

  service { 'salt-master':
    ensure  => 'running',
    enable  => true,
    require => Package['salt-master'],
  }

  ## Deploy the minion public key as derived from the puppet pubkey and
  ## exported in the salt::minion manifest.  This is already on the puppet
  ## master but needs to be extracted manually as shown in the commandline
  ## below, but this would be hard to detect change, so we use an exported
  ## resource and a custom fact instead:
  ##
  ## openssl x509 -pubkey -noout -in /var/lib/puppet/server/ssl/ca/signed/${::fqdn}.pem -out /etc/salt/pki/master/minions/${::fqdn}
  File <<| tag == salt_minion_pubkey |>>

  ## Remove any salt master pubkeys that are not current exported by a
  ## puppet agent/salt minion.  Remove any keys that have been accepted
  ## manaully with salt-key command (i.e. remove files not known to puppet).
  file { '/etc/salt/pki/master/minions/':
    ensure  => 'directory',
    purge   => true,
    recurse => true,
    force   => true,
    require => Package['salt-master'],
  }

  ## Because we use exported resources, there are timing issues where minions could
  ## be running with the wrong keys in place.  To keep things tidy, we purge any
  ## key requests or automatically denied keys.
  file { [ '/etc/salt/pki/master/minions_denied/', '/etc/salt/pki/master/minions_pre/' ]:
    ensure  => 'directory',
    purge   => true,
    recurse => true,
    force   => true,
    require => Package['salt-master'],
  }

}
