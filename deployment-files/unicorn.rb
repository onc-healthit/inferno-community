# frozen_string_literal: true

# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
@dir = '/var/www/inferno/'
@log_dir = '/var/unicorn/'

worker_processes 2
working_directory @dir

timeout 300

## SRM: Changing this to a TCP socket so the nginx can sit on another 'machine' (i.e. docker image)
# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
# listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64
listen 8080, tcp_nopush: true

# Set process id path
pid "#{@log_dir}pids/unicorn.pid"

# Set log file paths
stderr_path "#{@log_dir}log/unicorn.stderr.log"
stdout_path "#{@log_dir}log/unicorn.stdout.log"
