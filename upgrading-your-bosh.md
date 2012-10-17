# Upgrading your BOSH

BOSH is open source and a relatively young piece of software. You may quickly want to help and contribute to the project. This tutorial walks through how to upgrade your BOSH with a latest HEAD or branch or tag of the [https://github.com/cloudfoundry/bosh](bosh).

This tutorial assumes your BOSH was created from a stemcell or from an AWS AMI. There is an [overview page](../create-a-bosh/creating-a-bosh-overview.md) describing the creation options.


```
$ ssh ubuntu@inception-vm

> sudo su -

cd /var/vcap/bootstrap/bosh
git pull origin master

cd /var/vcap/bootstrap/bosh/common/
bundle install --without=development test
bundle exec rake install

cd /var/vcap/bootstrap/bosh/cli/
bundle install --without=development test
bundle exec rake install

cd /var/vcap/bootstrap/bosh/deployer/
bundle install --without=development test
bundle exec rake install
```