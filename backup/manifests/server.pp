class backup::server () {

  if $::dmi['manufacturer'] != 'Google' {
    fail( 'We only support Google snapshot based backups.' )
  }

  # Server backup script and precheck scripts.
  file { '/usr/local/bin/':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    recurse => 'remote',
    source  => 'puppet:///modules/backup/usr/local/bin/', 
  } ->

  # Realise all exported backup jobs (after script in place).
  File <<| tag == 'backup' |>>

}
