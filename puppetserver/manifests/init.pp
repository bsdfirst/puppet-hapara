class puppetserver (

  # List of enviroments for which puppet should attempt to clone git repositories.
  $environments,

  # List of domains that certificates should be auto signed for
  # (default to the same domain that the puppetmaster exists in).
  $autosign_domains = [ $::domain ],

  # Java memory flags (https://docs.puppet.com/puppetserver/latest/tuning_guide.html).
  $xms         = '1g',
  $xmx         = '2g',
  $maxpermsize = '256m',

  # How many jRuby instances should we spawn - default to the number of CPU cores - 1.
  $max_instances = $processors['count'] - 1,

) {

  package { 'puppetserver':
    ensure => 'installed',
    before => Class['puppetserver::hiera'],  # we use before here (rather than require from the other end) so that we can call the puppetserver::hiera class by itself when bootstrapping puppetmasters
  }

  # Ensure user puppet can create files in code directory.
  file { '/etc/puppetlabs/code':
    ensure  => 'directory',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0750',
  }

  # Manage puppetserver configuration file (notably java params).
  file { '/etc/default/puppetserver':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/defaults.erb"),
    notify  => Service['puppetserver'],
  }

  # Configure the number of jRuby interpreters to spawn.
  file_line { 'puppetserver_max_active_instances':
    ensure => 'present',
    path   => '/etc/puppetlabs/puppetserver/conf.d/puppetserver.conf',
    line   => "    max-active-instances: ${max_instances}",
    match  => 'max-active-instances:',
    notify => Service['puppetserver'],
  }

  # Cause the puppetserver to also read the client ruby lib path.
  # https://tickets.puppetlabs.com/browse/SERVER-1014
  # https://tickets.puppetlabs.com/browse/SERVER-571
  file_line { 'puppetserver_ruby_load_path':
    ensure => 'present',
    path   => '/etc/puppetlabs/puppetserver/conf.d/puppetserver.conf',
    line   => '    ruby-load-path: [/opt/puppetlabs/puppet/lib/ruby/vendor_ruby, /opt/puppetlabs/puppet/cache/lib]',
    match  => 'ruby-load-path:',
    notify => Service['puppetserver'],
  }

  # Manage autosigning configuration.
  file { '/etc/puppetlabs/puppet/autosign.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/autosign.conf.erb"),
    notify  => Service['puppetserver'],
  }

  # Configure hiera (this is abstracted to a non-parametised class so that
  # we can call it with puppet apply when bootstrapping a puppetmaster.
  class { 'puppetserver::hiera': }

  # Start the pupetserver on boot.  (We don't ensure running as this is really annoying if you are
  # trying to run the puppetserver in the foreground for debugging purposes and it must already be
  # running for this manifest to even apply.  We still retain the service defintion to set enable
  # on boot and for subscribe/notify.
  service { 'puppetserver':
    enable    => true,
    require   => [ Package['puppetserver'], File['/etc/default/puppetserver'], ],
    subscribe => [ Class['puppetserver::hiera'], Class['hiera'], ],  # we do this here so that we can call the puppetserver::hiera
                                                                     # class by itself when bootstrapping puppetmasters
  }

  # Check out all manifests from git (if bootstrapping installation).
  class { 'puppetserver::repos':
    environments => $environments,
    require      => [ Package['puppetserver'], Class['hiera'], ],
  }

  # Install cronjobs to automatically cleanup Google certificates if we are running in GCE.
  if $::dmi['manufacturer'] == 'Google' {
    class { 'puppetserver::google_orchestration': }  
  }

}
