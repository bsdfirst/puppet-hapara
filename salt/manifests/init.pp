class salt {

  logrotate::rotate { 'salt-common':
    patterns => [
      '/var/log/salt/master',
      '/var/log/salt/minion',
      '/var/log/salt/key',
    ],
  }

}
