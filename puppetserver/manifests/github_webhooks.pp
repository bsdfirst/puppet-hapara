class puppetserver::github_webhooks (

  # Optional arguments.
  $user     = 'puppet',   # created by puppet package
  $group    = 'puppet',   # created by puppet package
  $basepath = '/srv/github_webhooks',

  # Secret key (as specified in github and hiera) if request hashing desired.
  $secret = undef,

  # Port/IP to bind.
  $bind,

) {

  file { $basepath:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
  }

  file { "$basepath/source":
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0640',
    purge   => true,
    force   => true,
    recurse => true,
    ignore  => '*.pyc',
    require => File[$basepath],
  }

  file { "$basepath/source/github_webhooks.py":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template("${module_name}/github_webhooks/github_webhooks.py.erb"),
    require => [ File["$basepath/source"], Class['git'], ],
    notify  => Python::Gunicorn['github_webhooks'],
  }

  file { "$basepath/source/requirements.txt":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template("${module_name}/github_webhooks/requirements.txt.erb"),
    require => File["$basepath/source"],
    notify  => Python::Virtualenv["$basepath/virtenv"],
  }

  python::virtualenv { "$basepath/virtenv":
    ensure       => 'present',
    version      => 'system',
    requirements => "$basepath/source/requirements.txt",
    systempkgs   => true,
    owner        => $user,
    group        => $group,
    cwd          => $basepath,
    require      => [ File[$basepath], File["$basepath/source/requirements.txt"], ],
    notify       => Python::Gunicorn['github_webhooks'],
  }

  python::gunicorn { 'github_webhooks':
    ensure      => 'present',
    virtualenv  => "$basepath/virtenv",
    mode        => 'wsgi',
    dir         => "$basepath/source",
    bind        => $bind,
    owner       => $user,
    group       => $group,
    appmodule   => 'github_webhooks:app',
    require     => [
                     Python::Virtualenv["$basepath/virtenv"],
                     File["$basepath/source/github_webhooks.py"],
                   ],
  }

}
