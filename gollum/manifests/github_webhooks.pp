class gollum::github_webhooks (

  # User to own files.
  $user,
  $group,

  # Path to webhooks application.
  $base_path = '/srv/github_webhooks',

  # Path to repository files to manage.
  $repo_path,

  # Secret key (as specified in github and hiera) if request hashing desired.
  $secret = undef,

  # Port/IP to bind.
  $port,

) {

  # Include python base.
  class { 'python':
    ensure          => 'present',
    pip             => 'present',
    virtualenv      => 'present',
    gunicorn        => 'present',
    manage_gunicorn => true,
  }

  # The config directory is not created by the gunicorn package under xenial but require by the python::virtenv define.
  file { '/etc/gunicorn.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => Class['python'],
  }

  file { $base_path:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
  }

  file { "$base_path/source":
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0640',
    purge   => true,
    force   => true,
    recurse => true,
    ignore  => '*.pyc',
    require => File[$base_path],
  }

  file { "$base_path/source/github_webhooks.py":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template("${module_name}/github_webhooks/github_webhooks.py.erb"),
    require => [ File["$base_path/source"], Class['git'], ],
    notify  => Python::Gunicorn['github_webhooks'],
  }

  file { "$base_path/source/requirements.txt":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template("${module_name}/github_webhooks/requirements.txt.erb"),
    require => File["$base_path/source"],
    notify  => Python::Virtualenv["$base_path/virtenv"],
  }

  python::virtualenv { "$base_path/virtenv":
    ensure       => 'present',
    version      => 'system',
    requirements => "$base_path/source/requirements.txt",
    systempkgs   => true,
    owner        => $user,
    group        => $group,
    cwd          => $base_path,
    require      => [ File[$base_path], File["$base_path/source/requirements.txt"], ],
    notify       => Python::Gunicorn['github_webhooks'],
  }

  python::gunicorn { 'github_webhooks':
    ensure      => 'present',
    virtualenv  => "$base_path/virtenv",
    mode        => 'wsgi',
    dir         => "$base_path/source",
    bind        => ":${port}",
    owner       => $user,
    group       => $group,
    appmodule   => 'github_webhooks:app',
    require     => [
                     Python::Virtualenv["$base_path/virtenv"],
                     File["$base_path/source/github_webhooks.py"],
                   ],
  }

  # @TODO cron to pull

}
