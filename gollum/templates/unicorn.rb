worker_processes 10

working_directory "<%= @working_path %>"
listen <%= @bind_port %>, :tcp_nopush => true

stderr_path "<%= @log_path %>/unicorn.stderr.log"
stdout_path "<%= @log_path %>/unicorn.stdout.log"

preload_app true
