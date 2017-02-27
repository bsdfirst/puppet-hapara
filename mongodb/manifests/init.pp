## Note, at the time of implementation, the puppetlabs/mongodb module didn't work
## very well for MongoDB 3.x, so we have developed our own.  It's not very flexible
## and the exec's are probably not as robust as properly parsing the mongo json
## output; however, it currently works better than the puppetlabs module.  We
## only support deployment as a replicaset (even if it is a single node).

## THIS CLASS WILL NOT REMOVE NODES FROM A CLUSTER IF THEY ARE REMOVED FROM HIERA ###


class mongodb (

  # Should we add the upstream 10gen repos.
  $manage_repo = true,

  # What port/ip should we bind.
  $port = '27017',
  $bind = [ '0.0.0.0' ],

  # Max connections we should accept.
  $max_connections = 51200,  # 51,200 appears to be the maximum under xenial

  # Threshold in ms over which a query is considered "slow".
  $slowop_threshold = 100,

  # Enable slow query logging only for queries slower than threshold by default.
  $slowop_mode = 'slowOp',

  # Replicaset name.
  $replset_name,

  # Replicaset nodes.
  $replset_nodes,

  # Use the 'local' readConcern by default.
  $enable_majority_read_concern = false,

) {

  # The current mongodb module only installs the 2.6 repos, we install
  # the upstream repos ourselves to get the 3.x series which is current
  # stable.
  if ( $manage_repo ) {
    apt::source { 'mongodb':
      comment  => 'The 10gen Mongo 3.x upstream repository.',
      location => 'http://repo.mongodb.org/apt/ubuntu',
      repos    => 'multiverse',
      release  => "${::os['distro']['codename']}/mongodb-org/stable",
      key      => {
                    'id'     => '492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10',
                    'server' => 'keyserver.ubuntu.com',
                  },
      include  => { 'src' => false },
      before   => Package['mongodb-org'],
    }
  }

  # We must put the main config file in place before the package install as
  # the post install script in the deb starts mongo and creates the data directory.
  # Some options such as directoryPerDB cannot be changed without clearing this directory.
  file { '/etc/mongod.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${module_name}/mongod.conf.erb"),
    before  => Package['mongodb-org'],
    notify  => Service['mongod'],
  }

  package { 'mongodb-org':
    ensure => 'installed',
  }

  logrotate::rotate { 'mongo':
    patterns   => [ '/var/log/mongodb/*.log', ],
    postrotate => '/usr/bin/killall -USR1 mongod',
  }

  # The xenial package fails to include a systemd unit file so include
  # our own one here.  There is no harm in pushing this to trusy instances
  # as well as xenial instances.
  file { '/etc/systemd/system/mongod.service':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => "puppet:///modules/${module_name}/etc/systemd/system/mongod.service",
    notify => Service['mongod'], 
    before => Service['mongod'],
  }

  service { 'mongod':
    ensure  => 'running',
    enable  => true,
    require => [ Package['mongodb-org'], File['/etc/mongod.conf'], ],
  }

  # We assume that there is always one node in the replset_nodes array.  We use this
  # node to instantiate the replica set and configure it as the preferential master.
  # (The replset_nodes array may be a hostname or fqdn and may contain a port number,
  # so we strip it back to a bare hostname to compare with the $::hostname fact.)
  $matches = $replset_nodes[0].match( /^([a-zA-Z0-9-]+)(?:[.:].*)?$/ )
  $primary_hostname = $matches[1]

  # If we are the first node, then we are the primary.
  if $primary_hostname == $::hostname {

    # Initilise cluster - loop through all nodes defined in hiera.
    $replset_nodes.each | Integer $index, String $node | {

     # The first node must initiate the cluster.  All other nodes must be "added".
     if $index == 0 {

        # Use the explicit hostname when we create the replicaset otherwise the first node gets added as the bindIp.
        $rs_conf = sprintf( '{"_id":"%s","members":[{"_id":0,"host":"%s","priority":1000}]}', $replset_name, $node )

        # Initiate the cluster if it is not already running. (The init script returns before mongo is actually
        # listening, so we introduce a small delay into the check to try to reduce the number of puppet runs
        # required to get mongo up.)
        exec { "rs_initiate_${replset_name}":
          path    => '/sbin:/bin:/usr/sbin:/usr/bin',
          onlyif  => "sleep 2; mongo --quiet --eval 'printjson(rs.status())' | egrep -q '\"code\"\s+:\s+94'",
          command => "mongo --quiet --eval 'printjson(rs.initiate($rs_conf))'",
          require => Service['mongod'],
        }
 
      } else {

        # Add node to the already running cluster. (The init script returns before mongo is actually
        # listening, so we introduce a small delay into the check to try to reduce the number of puppet runs
        # required to get mongo up.)
        exec { "rs_add_${replset_name}_${node}":
          path    => '/sbin:/bin/:/usr/sbin:/usr/bin',
          unless  => "sleep 2; mongo --quiet --eval 'printjson(rs.conf())' | egrep '\"host\"\s+:\s+\"${node}'",
          command => "mongo --quiet --eval 'printjson(rs.add(\"${node}\"))'",
          require => [ Service['mongod'], Exec["rs_initiate_${replset_name}"], ],
        }

      }
    
    }

  }

}
