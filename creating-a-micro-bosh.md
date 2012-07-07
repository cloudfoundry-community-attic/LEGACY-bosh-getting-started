# Create a Micro BOSH

This tutorial shows you how to create your first BOSH (called a Micro BOSH as all the components are in on VM), and the preceding steps for preparing the Inception VM that will be required.

That is, there are three machines/VM being referenced in this tutorial. We will create two VMs in two different AWS regions, and there is your local machine (for example, an OS X machine)

1. Local machine - use fog to provision Inception VM; use ssh to access/prepare Inception VM
1. Inception VM - prepare an available Ubuntu VM; we'll create a new one
1. Micro BOSH VM - use BOSH CLI to bootstrap a new VM that is a BOSH (called "Micro BOSH")

That is, by the end of this tutorial you will have two Ubuntu VMs. An Inception VM used to create a BOSH VM.

This tutorial is the preferred method for bootstrapping a BOSH. Alternately, you can [create a BOSH from scratch](creating-a-bosh-from-scratch.md) using provided chef recipes.

## Create the Inception VM

This short section is only necessary if you do not have an available Ubuntu VM, such as you are on a Mac OS X machine or Windows machine.

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
export ORIGUSER=vcap
curl https://raw.github.com/drnic/bosh-getting-started/master/scripts/prepare_inception.sh | bash
source /etc/profile
```

After this script prepares the inception VM, it will display the help information for `bosh micro` CLI commands:

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

We will store them all in `/var/vcap/deployments` (created by `prepare_inception.sh`)

```
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

On your local machine using fog, provision an elastic public IP in the target infrastructure/region (us-west-2 in this tutorial):

``` ruby
>> connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
>> address = connection.addresses.create
>> address.public_ip
"1.2.3.4"
```

The "1.2.3.4" value will replace `IPADDRESS` in the micro_bosh.yml below.

Back to the Inception VM... 

Create an AWS keypair and store the `.pem` file. Inside the Inception VM:

```
curl https://raw.github.com/drnic/bosh-getting-started/master/scripts/create_keypair > /tmp/create_keypair
chmod 755 /tmp/create_keypair
/tmp/create_keypair ACCESS_KEY_ID SECRET_ACCESS_KEY ec2
```

You can pass an encrypted password to the Micro BOSH. Run the following for you own `PASSWORD` and replace `SALTED_PASSWORD` with the returned value.

```
mkpasswd -m sha-512 PASSWORD
```

Create a deployments folder for our `micro_bosh.yml` file. For AWS us-east-1 (Virginia), name the folder `microbosh-aws-us-east-1` so you can quickly tell the purpose of the Micro BOSH.

Inside this folder, create `/var/vcap/deployments/microbosh-aws-us-east-1/micro_bosh.yml` file as follows:

```
mkdir -p /var/vcap/deployments/microbosh-aws-us-east-1
curl https://raw.github.com/drnic/bosh-getting-started/master/examples/microbosh/micro_bosh.yml > /var/vcap/deployments/microbosh-aws-us-east-1/micro_bosh.yml
vim /var/vcap/deployments/microbosh-aws-us-east-1/micro_bosh.yml
```

Inside vim, edit the ALLCAPS variables:

* replace SALTED_PASSWORD with your `mkpasswd` encrypted password
* replace IPADDRESS with your elastic IP
* replace ACCESS_KEY_ID and SECRET_ACCESS_KEY with your AWS credentials

```
---
name: microbosh-aws-us-east-1

env:
  bosh:
    password: SALTED_PASSWORD

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
      ec2_endpoint: ec2.us-east-1.amazonaws.com
      default_key_name: ec2
      default_security_groups: ["default"]
      ec2_private_key: /home/vcap/.ssh/ec2.pem
```



```
$ bosh micro deployment microbosh-aws-us-east-1
WARNING! Your target has been changed to `http://1.2.3.4:25555'!
Deployment set to '/var/vcap/deployments/microbosh-aws-us-east-1/micro_bosh.yml'

$ bosh micro deploy ami-0743ef6e
```


## Build from a stemcell

Alternately, create the base AMI image ("stemcell" in BOSH terminology) used to create a Micro BOSH VM. This requires that the Inception VM is in the same account/region as the Micro BOSH will be.

```
bosh public stemcells
# confirm that micro-bosh-stemcell-0.1.0.tgz is the latest one
bosh download public stemcell micro-bosh-stemcell-0.1.0.tgz
bosh micro deploy micro-bosh-stemcell-0.1.0.tgz
```

NOTE: You want one called "micro-bosh-stemcell..." rather than a base stemcell with "aws" in its name.
