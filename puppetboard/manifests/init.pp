class puppetboard (

  # Optional arguments.
  $user     = 'puppetboard',
  $group    = 'puppetboard',
  $basepath = '/srv/puppetboard',
  $upstream = 'https://github.com/puppet-community/puppetboard.git',
  $revision = 'origin/master',

  # Require the bind ip/port to be passed.
  $bind,

) {

  group { $group:
    ensure => 'present',
  }

  user { $user:
    ensure     => 'present',
    shell      => '/bin/false',
    managehome => false,
    home       => $basepath,
    gid        => $group,
    system     => true,
    require    => Group[$group],
  }

  file { $basepath:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => User[$user],
  }

  git::deploy { "$basepath/source":
    owner    => $user,
    group    => $group,
    source   => $upstream,
    revision => $revision,
    require  => File[$basepath],
    notify   => Python::Gunicorn['puppetboard'],
  }

  python::virtualenv { "$basepath/virtenv":
    ensure       => 'present',
    version      => 'system',
    requirements => "$basepath/source/requirements.txt",
    systempkgs   => true,
    owner        => $user,
    group        => $group,
    cwd          => $basepath,
    require      => [ File[$basepath], Vcsrepo["$basepath/source"], ],
    notify       => Python::Gunicorn['puppetboard'],
  }

  file { "$basepath/settings.py":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0444',
    content => template("${module_name}/settings.py.erb"),
    require => File[$basepath],
    notify  => Python::Gunicorn['puppetboard'],
  }

  python::gunicorn { 'puppetboard':
    ensure      => 'present',
    virtualenv  => "$basepath/virtenv",
    mode        => 'wsgi',
    dir         => "$basepath/source",
    bind        => $bind,
    owner       => $user,
    group       => $group,
    environment => 'prod',
    osenv       => { 'PUPPETBOARD_SETTINGS' => "$basepath/settings.py" },
    appmodule   => 'puppetboard.app:app',
    require     => [
                     File["$basepath/settings.py"],
                     Python::Virtualenv["$basepath/virtenv"],
                     Git::Deploy["$basepath/source"],
                   ],
  }

}
