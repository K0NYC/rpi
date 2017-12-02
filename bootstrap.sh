#!/bin/bash -x

grep -q dtoverlay=w1-gpio /boot/config.txt || echo "dtoverlay=w1-gpio" >> /boot/config.txt

apt-get -y update
apt-get -y upgrade

# Install necessary software
apt-get install -y git python3-w1thermsensor python-pip python3-pip locate npm build-essential mosquitto
pip install awscli --upgrade
pip install boto3
pip3 install paho-mqtt
npm install -g npm@3.x

# Set AWS creds and config
if [[ ! -e $HOME/.aws/credentials ]]
then
	mkdir $HOME/.aws
	cat <<EOF > $HOME/.aws/credentials
[default]
AWS_ACCESS_KEY_ID=$1
AWS_SECRET_ACCESS_KEY=$2
AWS_DEFAULT_REGION=us-east-1
EOF
fi

if [[ ! -e $HOME/.aws/config ]]
then
	cat <<EOF > $HOME/.aws/config
[default]
region = us-east-1
EOF
fi

# Set aliases and PATH for pi
if [[ ! $(grep -q "alias ll='ls -alFG'" /home/pi/.bashrc) ]]
then
	cat <<EOF >> /home/pi/.bashrc
alias ll='ls -alFG'
alias python=python3
export PATH=$PATH:/usr/local/bin/aws:/usr/bin/npm
EOF
fi

# Copy .bashrc file to the root user for fancy prompt and aliases
cp /home/pi/.bashrc $HOME/.bashrc

# Install ssh keys
[[ ! -d $HOME/.ssh ]] && mkdir $HOME/.ssh && chmod 700 $HOME/.ssh
[[ ! -e $HOME/.ssh/authorized_keys ]] && aws s3 cp s3://us-east-1-rpi-creds/id_rsa.pub $HOME/.ssh/authorized_keys
[[ ! -e $HOME/.ssh/id_rsa ]] && aws s3 cp s3://us-east-1-rpi-creds/id_rsa $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/id_rsa

# Set up git repo
if [[ ! -e $HOME/.ssh/known_hosts ]] || [[ ! $(grep -q github.com $HOME/.ssh/known_hosts) ]]
then 
	cat <<EOF > $HOME/.ssh/known_hosts
github.com,192.30.253.113 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOF
fi

if [[ ! -d /opt/gits ]]
then
	mkdir -p /opt/gits
	cd /opt/gits
	git clone git@github.com:seledkinpylesos/rpi.git
fi

# Create boot script for modprobe
if [[ ! -e /etc/init.d/boot_script.sh ]]
then
	cat <<EOF > /etc/init.d/boot_script.sh
### BEGIN INIT INFO
# Provides:          boot_script.sh
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Run modprobe for digital temperature sensor
# Description:       Enable service provided by daemon.
### END INIT INFO

#!/bin/bash -ex

modprobe w1-gpio
modprobe w1-therm
>&2 echo "Executed modprobe"
EOF
	chmod +x /etc/init.d/boot_script.sh
	update-rc.d /etc/init.d/boot_script.sh defaults
fi

# Disable password auth over ssh
grep -q "PasswordAuthentication no" /etc/ssh/ssh_config || echo 'PasswordAuthentication no' >> /etc/ssh/ssh_config

# Install Node-Red
yes | bash <(curl -sL https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/update-nodejs-and-nodered)
systemctl enable nodered.service
ln -s /usr/bin/nodejs /usr/bin/node
cd $HOME/.node-red/
npm install node-red-contrib-ds18b20 node-red-contrib-aws-iot-hub node-red-node-aws node-red-contrib-aws node-red-node-pi-gpiod node-red-dashboard node-red-contrib-moment node-red-admin
sudo systemctl enable nodered.service
reboot

