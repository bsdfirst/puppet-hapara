class git (

  $manage_repo = true,

) {

  if ( $manage_repo ) {
    apt::ppa { 'ppa:git-core/ppa':
      before => Package['git'],
    }
  }

  package { 'git':
    ensure => 'installed',
  }
 
}
