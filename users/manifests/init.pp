class users (

  # Should we purge any non-system users that are not known to puppet.
  $purge = false,

  # If we are in Google Compute Engine, then should we disable the
  # portions of the google-daemon responsible for user management?
  $disable_google = true,

) {

  # Install additional shells (notably zsh, but others as required).
  package { [ 'zsh', 'fish', ]:
    ensure => 'installed',
  }

  # Read the users to create using the hiera_hash function rather than as a class
  # parameter so that we get a merge across the entire hierachy rather than the
  # most specific match.
  $users = hiera_hash( 'users', {} )
  validate_hash( $users )

  # If this class has been included, then we are managing users with Puppet.  If this machine
  # is also hosted in Google Compute, then we need to disable the portions of the google-daemon
  # that also try to manage users.
  if $::dmi['manufacturer'] == 'Google' {

    if str2bool( $disable_google ) {
      $google_ensure   = 'stopped'
      $google_enabled  = false
    } else {
      $google_ensure   = 'running'
      $google_enabled  = true
    }

    $accounts_services = $::os['distro']['codename'] ? {
      'trusty' => [ 'google-accounts-manager-service', 'google-accounts-manager-task' ],
      'xenial' => 'google-accounts-manager',
    }

    service { $accounts_services:
      ensure => $google_ensure,
      enable => $google_enabled,
    }

  }

  # Ensure the sudo group exists.
  group { 'sudo':
    ensure => 'present',
  }

  # Create a sudo entry for the sudo group.
  sudo::conf { 'admins':
    content  => "%sudo ALL=(ALL) NOPASSWD: ALL",
  }

  # Look through the users specified in Hiera.
  $users.each | String $user, Hash $params | {

    # If the user is "disabled" then remove the shell and ssh key.
    if $params['disabled'] and str2bool( $params['disabled'] ) {
      $shell      = '/usr/sbin/nologin'
      $ssh_ensure = 'absent'
    } else {
      $shell      = size( $params['shell'] ) ? { 0 => '/bin/bash', default => $params['shell'] }
      $ssh_ensure = 'present'
    }

    # Only create the user if a valid sshkey is specified (if an ssh key is removed for a user
    # then the global purge at the end of this class will cause the user to be removed - the
    # user's home directory will be retained).
    if $params['sshkey'] {

      # Validate any required fields.
      validate_string( $params['fullname'] )
      validate_string( $params['keytype'] )
      validate_string( $params['sshkey'] )
      validate_absolute_path( $shell, )

      # We explicitly set the home directory so we can use purge_ssh_keys.
      user { $user:
        ensure           => present,
        comment          => $params['fullname'],
        home             => "/home/${user}",  # purge_ssh_keys requires home to be set explicitly
        managehome       => true,
        shell            => $shell,
        expiry           => 'absent',
        password_max_age => '99999',  # clear a previously set password_max_age value
        purge_ssh_keys   => true,  # purge any ssh keys for this user not managed by puppet
        groups           => str2bool( $params['allowsudo'] ) ? { true => [ 'sudo' ], false => [] },  # should the user be in the sudo group?
        membership       => 'inclusive',  # remove the user from any other groups
      }

      # Deploy the users ssh public key into authorized_keys.
      ssh_authorized_key { "puppet:${user}":
        ensure  => $ssh_ensure,
        user    => $user,
        type    => $params['keytype'],
        key     => $params['sshkey'],
      }

    }

    # If the user has a Git repo specified in hiera, check this out into their home dir.
    if defined(User[$user]) and $params['repo'] {

      # The specified repo will be checked out into this directory.
      $cachedir = "/home/${user}/.cache/puppet-dotfiles"

      # Create the parent for the checkout directory if it doesn't already exist.
      file { "/home/${user}/.cache":
        ensure  => 'directory',
        owner   => $user,
        group   => $user,
        mode    => '0770',
        require => User[$user],
      }

      # Checkout the specified repo into the cache directory.
      git::deploy { $cachedir:
        owner    => $user,
        group    => $user,
        source   => $params['repo'],
        revision => size( $params['revision'] ) ? { 0 => 'origin/master', default => $params['revision'] },
        require  => [ User[$user], File["/home/${user}/.cache"], ],
      }

      # Copy files from the repo to the users home directory (will update changes but never
      # remove any files even in the even that they are removed from the repository).
      exec { "rsync_dotfiles_${user}":
        path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        user        => $user,
        command     => "rsync -avr ${cachedir}/ /home/${user}/ --exclude=.git",  # @TODO replace rsync as this checks the root (homedir) time which changes at login
        onlyif      => "test -n \"$( rsync -nair ${cachedir}/ /home/${user}/ --exclude=.git )\"",
        require     => Git::Deploy[$cachedir],
      }

    }

  }

  # Remove any non-system users that are not known to puppet if
  # purge set to true (won't remove users home directories).
  resources { 'user':
    purge              => str2bool( $purge ),
    unless_system_user => true,
  }

}
