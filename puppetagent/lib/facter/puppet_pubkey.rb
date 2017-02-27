# Fact to return the puppet agent public key (path hardcoded for Puppet 4).

# Give our fact a name.
Facter.add( 'puppet_pubkey' ) do
  setcode do

    # Determine our current FQDN
    fqdn = Facter.value(:fqdn)

    # Return the content of the puppet public key.
    File.open("/etc/puppetlabs/puppet/ssl/public_keys/#{fqdn}.pem", 'rb') { |f| f.read.chomp }

  end
end
