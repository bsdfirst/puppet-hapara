define git::deploy (

  # Path to deploy files into (inherit resource title by default).
  $path = $name,

  # Upstream git URI.
  $source,

  # Hash/branch/tag to deploy.
  $ensure = 'present',  # can also set latest, but this causes a re-clone every run
  $revision,

  # User that should own the checked out files (default to 'root' as it always exists).
  $owner = 'root',
  $group = 'root',

  # Overwrite any existing files in directory on initial checkout?
  $force = false,

  # Specify an ssh user/key to use for authenticating ssh type upstream sources.
  $user = undef,
  $identity = undef,

  # List any files that should not be touched by vcsrepo - in the same manner as gitignore.
  $excludes = undef,

  # Should we perform a git reset/clean as well as calling vcsrepo.
  $reset = true,
  $clean = true,

) {

  # Clone and make sure we are at the correct branch/tag/sha compared to upstream.
  vcsrepo { $path:
    ensure    => $ensure,
    provider  => 'git',
    source    => $source,
    revision  => $revision,
    owner     => $owner,
    group     => $group,
    user      => $user,
    force     => $force,
    excludes  => $excludes,
    identity  => $identity,
    require   => Class['git'],
  }

  if $clean {
    # Remove any files that have been added in the local repo that are not in
    # the remote.  We do this as root in case they are owned by the root user.
    exec { "git_clean_$path":
      command => 'git clean -df',
      onlyif  => 'git status --porcelain | grep -q ^??',
      cwd     => $path,
      user    => 'root',
      path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      require => Vcsrepo[$path],
    }
  }

  if $reset {
    # Correct any files that have been locally modified and commited - vcsrepo will not do this.
    exec { "git_reset_$path":
      command => "git reset $revision --hard",
      onlyif  => 'test "$(git status --porcelain | grep -qv ^?? | wc -l)" -ne 0',
      cwd     => $path,
      user    => $owner,
      path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      require => defined( Exec["git_clean_$path"] ) ? { true => Exec["git_clean_$path"], false => undef },
    }
  }

}
