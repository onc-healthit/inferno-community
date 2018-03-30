Setup Instructions for AWS EC2
==============================



1. Launch the Amazon Machine Image(AMI)

Launch the AMI `ami-7d2aec00`. The following link can help start this process. 

https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LaunchInstanceWizard:ami=ami-7d2aec00

(A micro-instance should suffice in situations where traffic will be low.)

2. Connect to the Server.

Use you favorite ssh client to connect to the server.

3. Change your hostname

Change the `server_name` variable in `/etc/nginx/nginx.conf` to
your desired hostname and then restart nginx with the following command.

    sudo service nginx restart


(Make sure this value is configured in your network's DNS settings.)


4. Start Unicorn


Issue the following commands to start and daemonize unicorn.


    cd /var/www/crucible_smart_app
    unicorn -D


Now point your browser to http://[your hostname] to use your copy of the Crucible Smart App.

