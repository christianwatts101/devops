
sudo yum --security upgrade


# Install yum-cron
sudo yum install yum-cron

# Configure yum-cron
sudo vim /etc/yum/yum-cron.conf

Set the following

update_cmd = security
apply_updates = yes

Then restart the service created by installing this package:

sudo systemctl status yum-cron
sudo systemctl enable yum-cron
# Or "restart" if already started
sudo systemctl start yum-cron