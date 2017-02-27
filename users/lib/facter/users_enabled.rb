# Fact to list all users that could be used to remotely access a system.

# Give our fact a name.
Facter.add( 'users_enabled' ) do
  setcode do

    # Get list of users defined on system and break into an array we can reference easily.
    cmd_output = Facter::Util::Resolution::exec( 'getent passwd' )
    users = Hash.new
    enabled_users = Array.new

    # Loop through each line from the passwd datbase and split the fields.
    cmd_output.each_line do | line |
      fields = line.strip.split( /:/ )
      users[fields[0]] = {
        uid:         fields[2],
        gid:         fields[3],
        gecos:       fields[4],
        home:        fields[5],
        shell:       fields[6],
        login_shell: true,  # fail-safe
        has_passwd:  true,  # fail-safe
        has_sshkey:  true,  # fail-safe
      }
    end

    # Loop through each user and perform access checks.
    users.each do | user, fields |

      # Check if the user has a password defined.
      users[user][:has_passwd] = false if /^\S+\s+(L|NP)/.match( Facter::Util::Resolution::exec( "passwd -S #{user}" ) )

      # Check if the user has an ssh key defined.
      users[user][:has_sshkey] = false if ! File.size?( "#{users[user][:home]}/.ssh/authorized_keys" )

      # Simple check to see if shell valid for login.
      users[user][:login_shell] = false if not users[user][:shell] or /(false|nologin)$/.match( users[user][:shell] )

      # Build a list of enabled users.
      enabled_users.push( user ) if users[user][:login_shell] and ( users[user][:has_sshkey] or users[user][:has_passwd] )

    end

    # Return the list of users as an array.
    enabled_users.sort

  end
end
