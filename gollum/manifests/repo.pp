class gollum::repo (

  # User to own files.
  $user,
  $group,

  # Home directory of user.
  $user_home,

  # Path to repository files to manage.
  $repo_path,

  # Clone source.
  $upstream,

) {

  # Create ssh directory.
  file { "${user_home}/.ssh":
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0700',
  }

  # Create cron job to update local repo periodically in case the github webhook fails.
  cron::job { 'gollum':
    timespec => '00 * * * *',
    command  => "ssh-agent sh -c 'cd ${repo_path} && ssh-add ~${user}/.ssh/id_rsa-github 2>/dev/null && git fetch --all >/dev/null 2>&1'",
    require => Exec['create_repo_mirror'],
  }

  # Add github.com ssh fingerprint for deploy process.
  exec { 'github_ssh_fingerprint':
    user    => $user,
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    command => "ssh-keyscan -t rsa github.com > ${user_home}/.ssh/known_hosts",
    creates => "${user_home}/.ssh/known_hosts",
    require => File["${user_home}/.ssh"],
  }

  exec { 'github_ssh_deploykey':
    user    => $user,
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => "${user_home}/.ssh/id_rsa-github",
    command => "ssh-keygen -b 4096 -N '' -f ${user_home}/.ssh/id_rsa-github",
    require => File["${user_home}/.ssh"],
  }

  exec { 'create_repo_mirror':
    user    => $user,
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    command => "ssh-agent sh -c 'ssh-add ${user_home}/.ssh/id_rsa-github && git clone --bare --mirror ${upstream} ${repo_path}'",
    creates => "${repo_path}/config", 
    require => [ Exec['github_ssh_fingerprint'], Exec['github_ssh_deploykey'], File["${user_home}/.ssh"], ],
  }

}
