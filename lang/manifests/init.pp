class lang () {

  # The saz/locale module from the forge requires the directory
  # /var/lib/locales/supported.d/local to exist in the filesystem.
  # This directory exists in the base filesystem for Trusty, but
  # is provided by the language packs in Xenial.

  package { 'language-pack-en':
    ensure => 'installed',
  } ->
  class { 'locales': }

}
