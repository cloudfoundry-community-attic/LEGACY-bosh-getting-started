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

Install fog, \~/.fog credentials (for AWS), and \~/.ssh/id_rsa(.pub) keys

Install fog

```
gem install fog
```

Example \~/.fog credentials:

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
puts server.ssh("whoami").first.stdout
```

The AWS VM has an available public URL:

```
server.dns_name
"ec2-10-9-8-7.compute-1.amazonaws.com"
```

We have now created a fresh Ubuntu VM that we will use to fetch the BOSH source and then launch the Micro BOSH deployer sequence to create a BOSH VM.

## Preparation

We now need to prepare our Ubuntu VM with the source code to be able to run the Micro BOSH deployment command.

These steps come from the [BOSH documentation](https://github.com/cloudfoundry/oss-docs/blob/master/bosh/documentation/documentation.md#bosh-deployer).

```
sudo su -
groupadd vcap 
useradd vcap -m -g vcap

mkdir -p /var/vcap/
cp /home/ubuntu/.ssh/authorized_keys /var/vcap/

vim /etc/apt/sources.list
```

Add the following line. **If you're in a different AWS region, change the URL prefix.**

```
deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ lucid multiverse
```

Back in the remote terminal (you can copy and paste each chunk):

```
apt-get update
apt-get install git-core libsqlite3-dev genisoimage -y

mkdir /var/vcap/bootstrap
cd /var/vcap/bootstrap
git clone https://github.com/cloudfoundry/bosh.git
cd /var/vcap/bootstrap/bosh/release/template/instance
./prepare_instance.sh

chmod 777 /var/vcap/deploy

export bosh_app_dir=/var/vcap
export PATH=${bosh_app_dir}/bosh/bin:$PATH

exit
```

NOTE: The prepare_instance.sh script installs more things than necessary, since it is designed for preparing the current VM for becoming BOSH. The things that it installs that are important are:

* Ruby 1.8.7 (and its dependencies)
* Rubygems 1.5.2

```
$ ruby -v
ruby 1.8.7 (2010-08-16 patchlevel 302) [x86_64-linux]
$ gem -v
1.5.2
```

TODO: Create a prepare_instance.sh script that does all the above.

```
gem install bundler
cd /var/vcap/bootstrap/bosh/cli/
bundle install
bundle exec rake install

cd /var/vcap/bootstrap/bosh/deployer/

# patch for matching bosh_cli gem (http://reviews.cloudfoundry.org/6937)
git remote add drnic https://github.com/drnic/bosh.git
git fetch drnic
git checkout -b deployer-bump-bosh-cli
git pull drnic deployer-bump-bosh-cli

bundle install
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

