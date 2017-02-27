class gollum (

  # Which port should we bind.
  $bind_port,

  # Path to deploy app + doc repo.
  $path = '/srv/gollum',

  # Upstream repo to clone.
  $upstream,

  # Github webhooks port/secret.
  $webhooks_secret,
  $webhooks_port,

  # Path to hold log files.
  $log_path = '/var/log/gollum',

  # Oauth details to authenticate against google.
  $oauth_account,
  $oauth_secret,

  # Users MUST be in this domain to be valid.
  $oauth_user_domain,

  # URI to a PlantUML server.
  $plantuml_url = '',

  # User/group to run as.
  $user  = 'gollum',
  $group = 'gollum',

) {

  # We create the repository in a directory owned by Gollum so that the clone doesn't have permissions issues.
  $working_path = "${path}/app"
  $repo_path    = "${path}/repo"

  # Deploy github deploy keys, initial checkout of repo.
  class { 'gollum::repo':
    user      => $user,
    group     => $group,
    repo_path => $repo_path,
    upstream  => $upstream,
    user_home => $path,
    require   => File[$path],
  }

  # Service to respond to github webhooks and 'git fetch' on push events.
  class { 'gollum::github_webhooks':
    user      => $user,
    group     => $group,
    repo_path => $repo_path,
    secret    => $webhooks_secret,
    port      => $webhooks_port,
    require   => Class['gollum::repo'],
  }

  # Default for all following file blocks.
  File {
    ensure => 'present',
    owner  => $user,
    group  => $group,
    mode   => '0444',
  }

  # Reqired OS packages.
  $required_packages = [
    'build-essential',
    'cmake',
    'docutils-common',
    'libicu-dev',
    'make',
    'perl',
    'pkg-config',
    'python-docutils',
    'python3-docutils',
    'python-pygments',
    'python3-pygments',
    'ruby',
    'ruby-dev',
    'zlib1g',
    'zlib1g-dev',
  ]

  # Required Ruby Gems.
    $required_gems = [
    'asciidoctor',
    'bundler',
    'creole',
    'expression_parser',
    'github-markup',
    'github-markdown',
    'gollum',
    'htmlentities',
    'omniauth-google-oauth2',
    'omnigollum',
    'org-ruby',
    'twitter-text',
    'unf',
    'unicorn',
    'wikicloth',
    'RedCloth',
  ]

  # Install required packages.  There is likely some overlap with other Puppet modules and thus
  # room for abstraction here; however, Gollum is likely the only thing on the node it is applied
  # to, so to keep things simple we just install all required packages from this module.
  package { $required_packages:
    ensure => 'installed',
    before => Service['gollum'],
  } ->
  package { $required_gems:
    ensure   => 'installed',
    provider => 'gem',
    before   => Service['gollum'],
  }

  # Create group for gollum/unicorn to run as.
  group { $group:
    ensure => 'present',
    system => true,
  }

  # Create user for gollum/unicorn to run as.
  user { $user:
    ensure     => 'present',
    gid        => $group,
    home       => $path,
    managehome => false,
    system     => true,
  }

  # Create directory to hold application/unicorn config files.
  file { $path:
    ensure => 'directory',
    mode   => '0755',
  } ->
  file { $working_path:
    ensure => 'directory',
    mode   => '0755',
  }

  # Gollum config.
  file { "${working_path}/config.ru":
    content => template( "${module_name}/config.ru" ),
    require => File[$working_path],
    notify  => Service['gollum'],
  }

  # Unicorn install config.
  file { "${working_path}/unicorn.rb":
    content => template( "${module_name}/unicorn.rb" ),
    require => File[$working_path],
    notify  => Service['gollum'],
  }

  # Create systemd start file for unicorn.
  systemd::unit_file { 'gollum.service':
    content => template( "${module_name}/gollum.service" ),
  }

  # Manage the unicorn instance service.
  service { 'gollum':
    ensure  => 'running',
    enable  => true,
    require => [
      File["${working_path}/config.ru"],
      File["${working_path}/unicorn.rb"],
      File[$log_path],
      Systemd::Unit_file['gollum.service'],
      Class['gollum::repo'],
    ],
  }

  # Create a separate directory to hold unicorn log files.
  file { $log_path:
    ensure => 'directory',
    mode   => '0750',
  }

  # Rotate log files.
  logrotate::rotate { 'gollum':
    patterns   => [ '/var/log/gollum/*.log', ],
    postrotate => "systemctl reload gollum",
    require    => File['/var/log/gollum'],
  }

}
