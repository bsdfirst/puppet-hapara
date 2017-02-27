class plantumlserver (

  # Which port should we bind.
  $bind_port,

  # Path to application config/working dir.
  $path = '/srv/plantumlserver',

  # User/group to run as.
  $user  = 'plantuml',
  $group = 'plantuml',

  # PlantUML server upstream and version.
  $upstream = 'https://github.com/plantuml/plantuml-server.git',
  $revision = 'origin/master',

) {

  # Default for all following file blocks.
  File {
    ensure => 'present',
    owner  => $user,
    group  => $group,
    mode   => '0444',
  }

  # Reqired OS packages.
  $required_packages = [
    'maven',
    'graphviz',
    'openjdk-8-jdk-headless',
  ]

  # Install the required packages.
  package { $required_packages:
    ensure   => 'installed',
    #before   => Service['plantumlserver'],
  }

  # Create group for plantuml/jetty to run as.
  group { $group:
    ensure => 'present',
    system => true,
  }

  # Create user for plantuml/jetty to run as.
  user { $user:
    ensure     => 'present',
    gid        => $group,
    home       => "${path}/home",
    managehome => false,
    system     => true,
  }

  # Create directory to hold source and working files.
  file { $path:
    ensure => 'directory',
    mode   => '0755',
  }

  # Create empty home directory (managehome won't recreate if it is removed later which breaks maven).
  file { "${path}/home":
    ensure => 'directory',
    mode   => '0755',
  }

  # Deploy plantuml files directly from git.
  git::deploy { "${path}/source":
    owner    => $user,
    group    => $group,
    source   => $upstream,
    revision => $revision,
  }

  # Create systemd start file for planuml/jetty.
  systemd::unit_file { 'plantuml.service':
    content => template( "${module_name}/plantuml.service" ),
  }

  # Manage the jetty instance service.
  service { 'plantuml':
    ensure  => 'running',
    enable  => true,
    require => [
      Systemd::Unit_file['plantuml.service'],
    ],
  }

}
