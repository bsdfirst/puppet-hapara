class slackcat (

  # What version of Slackcat should be installed (will be symlinked into /usr/local/bin).
  $version,

  # API integration token.
  $key,

  # Array of Unix users that should have the token configured.
  $users = [ 'root' ],

  # Path to slackcat binaries.
  $path = '/opt/slackcat',

) {

  # Default values for all subsequent File declarations.
  File {
    owner => 'root',
    group => 'root',
  }

  # Create the base directory to hold slackcat versioned binaries.
  file { $path:
    ensure => 'directory',
    mode   => '0755',
  }

  # Which binary are we dealing with?
  $filename = "slackcat-${version}-linux-amd64"

  # Download the binary from github.
  exec { 'download_slackcat':
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => "${path}/slackcat-${version}-linux-amd64",
    command => "wget https://github.com/vektorlab/slackcat/releases/download/v${version}/${filename} -O ${path}/${filename}",
    require => File[$path],
  }

  # Set permissions on the downloaded file.
  file { "${path}/${filename}":
    mode    => '0555',
    require => Exec['download_slackcat'],
  }

  # Point the symlink in the system path to the version specified.
  file { '/usr/local/bin/slackcat':
    ensure  => 'link',
    target  => "${path}/${filename}",
    require => [ Exec['download_slackcat'], File["${path}/${filename}"], ],
  }

  # Look through the users array and install the API key for each user specified.
  $users.each | $user | {

    # Determine the users home directory using the custom fact from the users module.
    $homedir = $::users[$user]['home']

    # Create the api key file in the users home directory.
    file { "${homedir}/.slackcat":
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0440',
      content => $key,
    }

  }

}
