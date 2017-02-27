## Note, this class performs the initial clone of any new environments/branches
## as specified in Hiera.  It also ensures these stay up to date (albeit lagging
## by one puppet run in the event that the Github webhooks integration fails.

class puppetserver::repos (

  $environments,

) {

  # Initial checkout of hieradata.
  git::deploy { '/etc/puppetlabs/code/hieradata':
    source   => '###REDACTED###',
    revision => 'origin/master',
    user     => 'puppet',
    owner    => 'puppet',
    group    => 'puppet',
    force    => true,
    identity => '~puppet/.ssh/id_rsa-hieradata',
  }

  # Initial checkout of manifests for each environment.
  $environments.each |$clone| {
    git::deploy { "/etc/puppetlabs/code/environments/${clone}":
      source   => '###REDACTED###',
      revision => "origin/${clone}",
      user     => 'puppet',
      owner    => 'puppet',
      group    => 'puppet',
      force    => true,
      identity => '~puppet/.ssh/id_rsa-environments',
    }
  }


}
