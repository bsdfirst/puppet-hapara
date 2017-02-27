#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'gollum/app'

# Don't know what this line does, but it was in the wiki examples and seems required.
Gollum::Page.send :remove_const, :FORMAT_NAMES if defined? Gollum::Page::FORMAT_NAMES

# Path to the wiki bare repo (does not work if set in wiki_options hash).
Precious::App.set( :gollum_path, '<%= @repo_path %>' )

# Gollum configuration.
wiki_options = {
  :css           => true,
  :js            => true,
  :ref           => 'master',
  :repo_is_bare  => true,
  :allow_editing => false,
  :emoji         => true,
  :mathjax       => true,
  :user_icons    => 'gravatar',
}
Precious::App.set(:wiki_options, wiki_options)

<% if @plantuml_url != '' -%>
# Where is our PlantUML server (don't try to test access as ruby breaks with embeded basic auth and the test fails).
Gollum::Filter::PlantUML.configure do | config |
  config.url  = "<%= @plantuml_url %>"
  config.test = true
end

<% end -%>
# Set environment to production (prevent Sinatra stack traces).
Precious::App.set( :environment, :production )

# Setup Omniauth via Omnigollum.
require 'omnigollum'
require 'omniauth-google-oauth2'

# Configure authentication options.
options = {

  # Configure omniauth against the Google Domain.
  :providers => Proc.new do
    provider :google_oauth2, '<%= @oauth_account %>', '<%= @oauth_secret %>', {
      :hd          => '<%= @oauth_user_domain %>',
      :access_type => 'online',   # we don't need offline access, prevent a confusing prompt if the user had previously oauth'd against the Google project
    }
  end,
  :dummy_auth => false,

  # Make the entire wiki require authentication.
  :protected_routes => [ '/*' ],

  # Specify committer name/email as provided by the omniauth package (for edits via the web interface).
  :author_format => Proc.new { | user | user.name },
  :author_email  => Proc.new { | user | user.email },

  # Empty string to allow any user that passes oauth to read the wiki.
  :authorized_users => ''

}

# Register the omnigollum extension.
Precious::App.set( :omnigollum, options )
Precious::App.register Omnigollum::Sinatra

# Run the app.
run Precious::App
