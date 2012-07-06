#!/usr/bin/env bash

orig_user=$(whoami)
groupadd vcap 
useradd vcap -m -g vcap
mkdir /home/vcap/.ssh
chown -R vcap:vcap /home/vcap/.ssh
cp /home/${orig_user}/.ssh/authorized_keys /home/vcap/.ssh/authorized_keys
cp /home/${orig_user}/.bashrc /home/vcap/

su -c "ssh-keygen -f ~/.ssh/id_rsa -N ''" vcap

bosh_app_dir=/var/vcap
mkdir -p ${bosh_app_dir}
cp /home/${orig_user}/.ssh/authorized_keys ${bosh_app_dir}/
mkdir -p ${bosh_app_dir}/bosh
export PATH=${bosh_app_dir}/bosh/bin:$PATH
mkdir -p ${bosh_app_dir}/deploy ${bosh_app_dir}/storage
chown vcap:vcap ${bosh_app_dir}/deploy ${bosh_app_dir}/storage
echo "export PATH=${bosh_app_dir}/bosh/bin:\$PATH" >> /root/.bashrc
echo "export PATH=${bosh_app_dir}/bosh/bin:\$PATH" >> /home/vcap/.bashrc

apt-get update
apt-get install build-essential libsqlite3-dev curl rsync git-core \
libmysqlclient-dev libxml2-dev libxslt-dev libpq-dev libsqlite3-dev genisoimage -y

echo "install: --no-ri --no-rdoc" > /etc/gemrc
echo "update: --no-ri --no-rdoc" > /etc/gemrc
curl -L get.rvm.io | bash -s stable
source /etc/profile
rvm install 1.9.3 # oh god this takes a long time
rvm 1.9.3
rvm alias create default 1.9.3


mkdir /var/vcap/bootstrap
cd /var/vcap/bootstrap
git clone https://github.com/cloudfoundry/bosh.git

cd /var/vcap/bootstrap/bosh/cli/
bundle install --without=development test
bundle exec rake install

cd /var/vcap/bootstrap/bosh/deployer/

# patch for matching bosh_cli gem (http://reviews.cloudfoundry.org/6937)
git remote add drnic https://github.com/drnic/bosh.git
git fetch drnic
git checkout -b deployer-bump-bosh-cli
git pull drnic deployer-bump-bosh-cli

bundle install --without=development test
bundle exec rake install

cd /var/vcap/bootstrap/bosh/aws_registry/
bundle install --without=development test
bundle exec rake install

bosh help micro
