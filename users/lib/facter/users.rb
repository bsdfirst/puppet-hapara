# Fact to list all users defined on a system.

# Give our fact a name.
Facter.add( 'users' ) do
  setcode do

    # Get list of users defined on system and break into an array we can reference easily.
    cmd_output = Facter::Util::Resolution::exec( 'getent passwd' )
    users = Hash.new

    # Loop through each line from the passwd datbase and split the fields.
    cmd_output.each_line do | line |
      fields = line.strip.split( /:/ )
      users[fields[0]] = {
        uid:        fields[2],
        gid:        fields[3],
        gecos:      fields[4],
        home:       fields[5],
        shell:      fields[6],
        has_passwd: true,  # fail-safe
        has_sshkey: true,  # fail-safe
      }
    end

    # Loop through each user and perform access checks.
    users.each do | user, fields |

      # Check if the user has a password defined.
      users[user][:has_passwd] = false if /^\S+\s+(L|NP)/.match( Facter::Util::Resolution::exec( "passwd -S #{user}" ) )

      # Check if the user has an ssh key defined.
      users[user][:has_sshkey] = false if ! File.file?( "#{users[user][:home]}/.ssh/authorized_keys" )

    end

    # Return the list of users as a hash sorted by uid.
    #users.sort { | a, b | a[1][:uid].to_i <=> b[1][:uid].to_i }
    users

  end
end
