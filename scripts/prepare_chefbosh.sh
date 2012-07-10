#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 1>&2
  exit 1
fi

if [[ -z $ORIGUSER ]]; then
  echo "SUGGESTION: $ORIGUSER to pass non-root username to copy authorized_keys and .bashrc to vcap user"
fi

groupadd vcap
useradd vcap -m -g vcap
mkdir -p /home/vcap/.ssh
chown -R vcap:vcap /home/vcap/.ssh

if [[ -f /home/vcap/.ssh/id_rsa ]]
then
  echo "public keys for vcap already exist, skipping..."
else
  su -c "ssh-keygen -f ~/.ssh/id_rsa -N ''" vcap
fi


echo 'deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ lucid multiverse' >> /etc/apt/sources.list

apt-get update
apt-get install git-core -y

bosh_app_dir=/var/vcap

mkdir -p ${bosh_app_dir}/deploy
chown vcap:vcap ${bosh_app_dir}/deploy

mkdir -p ${bosh_app_dir}/bootstrap
cd ${bosh_app_dir}/bootstrap
git clone https://github.com/cloudfoundry/bosh.git
cd bosh/release/template/instance
./prepare_instance.sh
