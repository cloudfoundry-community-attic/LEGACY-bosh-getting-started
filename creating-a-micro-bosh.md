# Create a Micro BOSH

These instructions are a combination of "Boot an AWS instance" and "Install BOSH via its chef_deployer"

* Use an available Ubuntu VM (we'll create a new one)
* Use BOSH CLI to bootstrap a new VM that is BOSH (called "Micro BOSH")

That is, by the end of this tutorial you will have two Ubuntu VMs. The initial VM will be used to create the second VM. The latter is BOSH.

This tutorial is the preferred method for bootstrapping a BOSH. Alternately, you can [create a BOSH from scratch](creating-a-bosh-from-scratch.md) using provided chef recipes.

## Create the first Ubuntu VM

This section is only necessary if you do not have an available Ubuntu VM, such as you are on a Mac OS X machine or Windows machine.

We will use fog to create the first Ubuntu VM on AWS. You could alternately create one any way that you want.

### Setup

Install fog, `~/.fog` credentials (for AWS), and `~/.ssh/id_rsa(.pub)` keys

Install fog

```
gem install fog
```

Example `~/.fog` credentials:

```
 :default:
  :aws_access_key_id:     PERSONAL_ACCESS_KEY
  :aws_secret_access_key: PERSONAL_SECRET
```

To create id_rsa keys:

```
$ ssh-keygen
```

### Boot Ubuntu instance

From Wesley's [fog blog post](http://www.engineyard.com/blog/2011/spinning-up-cloud-compute-instances/ "Spinning Up Cloud Compute Instances | Engine Yard Blog"), boot a vanilla Ubuntu 64-bit image:

```
$ fog
  Welcome to fog interactive!
  :default provides AWS and VirtualBox
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
server = connection.servers.bootstrap({
  :public_key_path => '~/.ssh/id_rsa.pub',
  :private_key_path => '~/.ssh/id_rsa',
  :flavor_id => 'm1.small', # 64 bit, small large
  :bits => 64,
  :username => 'ubuntu'
})
```

**Not using fog?** Here are a selection of AMIs to use that are [used by the fog](https://github.com/fog/fog/blob/master/lib/fog/aws/models/compute/server.rb#L55-66) example above:

```ruby
when 'ap-northeast-1'
  'ami-5e0fa45f'
when 'ap-southeast-1'
  'ami-f092eca2'
when 'eu-west-1'
  'ami-3d1f2b49'
when 'us-east-1'
  'ami-3202f25b'
when 'us-west-1'
  'ami-f5bfefb0'
when 'us-west-2'
  'ami-e0ec60d0'
```

Check that SSH key credentials are setup. The following should return "ubuntu", or similar, and shouldn't timeout.

```
>> puts server.ssh("whoami").first.stdout
ubuntu
```

The AWS VM has an available public URL:

```
>> puts server.dns_name
"ec2-10-9-8-7.compute-1.amazonaws.com"
```

We have now created a fresh Ubuntu VM that we will use to fetch the BOSH source and then launch the Micro BOSH deployer sequence to create a BOSH VM.

TODO: Attach EBS to /var/vcap/storage

## Preparation

We now need to prepare our Ubuntu VM with the source code to be able to run the Micro BOSH deployment command.

These steps come from the [BOSH documentation](https://github.com/cloudfoundry/oss-docs/blob/master/bosh/documentation/documentation.md#bosh-deployer).

```
$ ssh ubuntu@ec2-10-9-8-7.compute-1.amazonaws.com
sudo su -
orig_user=ubuntu
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
```

You can now confirm that you have the BOSH CLI `bosh` installed with the Micro BOSH deployer extensions:

```
$ bosh help micro
micro deploy <stemcell>   Deploy a micro BOSH instance to the currently 
                          selected deployment 
                          --update   update existing instance 
micro delete              Delete micro BOSH instance (including 
                          persistent disk) 
micro deployment [<name>] Choose micro deployment to work with 
micro agent <args>        Send agent messages 
micro apply <spec>        Apply spec 
micro status              Display micro BOSH deployment status 
micro deployments         Show the list of deployments 
```

## Deployment configuration

Each Micro BOSH that you create will be described by a single YAML configuration file, commonly named `micro_bosh.yml`. This allows you to easily reference different Micro BOSH deployments, boot them, change them, and delete them.

We will store them all in `/var/vcap/deployments`.

```
mkdir -p /var/vcap/deployments
chown vcap:vcap /var/vcap/deployments
cd /var/vcap/deployments
```

**Why have more than one MicroBOSH?** Each BOSH can only manage a single target infrastructure account and region. That is, if you want to use BOSH for multiple infrastructures (AWS, Rackspace, local vSphere), with different billing accounts, in different regions (AWS us-east-1, AWS us-west-2) then you will need a different BOSH for each permutation.

A simple convention for storing different `micro_bosh.yml` within our deployments folder could be to have folders named for the infrastructure/region:

```
# NOTE: only an example; you don't have any micro_bosh.yml files yet
$ find . -name micro_bosh.yml
  ./microbosh-aws-us-east-1/micro_bosh.yml
  ./microbosh-aws-us-west-2/micro_bosh.yml
```

**Where do I provision/host each Micro BOSH?** As above, each BOSH can manage VMs, persistant disk volumes and network associations in a single infrastructure region and account. That does not mean that the BOSH must be hosted within that same infrastructure/account. 

1. You could host all your BOSH deployments in the same region/account, with each one referencing external region/accounts.
1. You could host each BOSH deployment in the region/account that it will be managing.

For this tutorial, we will do option 2 and host the BOSH deployments within the same region/account that they will be managing. We will use the same AWS credentials used to create the first Ubuntu VM, but will deploy to a different region (although we could deploy to the same region; remember, each region requires a new BOSH deployment).

Provision an elastic public IP in the target infrastructure/region with fog:

``` ruby
>> connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-west-2' })
>> address = connection.addresses.create
>> address.public_ip
"1.2.3.4"
```

The "1.2.3.4" value will replace `IPADDRESS` in the micro_bosh.yml below.

For AWS us-west-2 (Oregon), create a `/var/vcap/deployments/microbosh-aws-us-west-2/micro_bosh.yml` file as follows:

```
---
name: microbosh-aws-us-west-2

env:
  bosh:
    password: $6$salt$password

logging:
  level: DEBUG

network:
  type: dynamic
  ip: IPADDRESS

resources:
  cloud_properties:
    instance_type: m1.small

cloud:
  plugin: aws
  properties:
    aws:
      access_key_id:     ACCESS_KEY_ID
      secret_access_key: SECRET_ACCESS_KEY
      ec2_endpoint: ec2.us-west-2.amazonaws.com
      default_key_name: fog_default
      default_security_groups: ["default"]
      ec2_private_key: /home/vcap/.ssh/id_rsa
```

TODO: How to create salted passwords?

Replace ACCESS_KEY_ID and SECRET_ACCESS_KEY with your AWS credentials.


```
$ bosh micro deployment microbosh-aws-us-west-2
WARNING! Your target has been changed to `http://1.2.3.4:25555'!
Deployment set to '/var/vcap/deployments/microbosh-aws-us-west-2/micro_bosh.yml'
```

Now fetch the basic AMI image ("stemcell" in BOSH terminology) used to create a Micro BOSH VM:

```
bosh public stemcells
# confirm that bosh-stemcell-aws-0.5.1.tgz is the latest one
bosh download public stemcell bosh-stemcell-aws-0.5.1.tgz
```

Now we can deploy our first Micro BOSH!

```
bosh micro deploy bosh-stemcell-aws-0.5.1.tgz
```
