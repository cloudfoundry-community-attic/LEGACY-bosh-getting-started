# Create a Micro BOSH from a stemcell

STATUS: Still being written.

WARNING: This tutorial requires a yet-to-be-released micro-bosh stemcell 0.6.1. That is, you can't follow this tutorial yet.

This tutorial shows you how to create your first BOSH on AWS (on any region or any available IaaS). This is one of several tutorials for [creating a BOSH](creating-a-bosh-overview.md).

In BOSH terminology, you will be creating a Micro BOSH. You will provision a single VM that contains all the parts of BOSH, which is bootstrapped from a pre-baked generic image (called a "stemcell" in BOSH language). That is, the image contains all the software packages required to run BOSH. During the deployment, a private AMI will be created from the stemcell, which will be used to boot the Micro BOSH VM.

This tutorial will take you through the steps related to preparation, creating the configuration file and using the BOSH CLI to deploy the Micro BOSH VM.

## What will happen in this tutorial

There are three machines/VM being referenced in this tutorial. In addition to your local machine, we will create two VMs in the same AWS region:

1. Local machine - use fog to provision Inception VM; use ssh to access/prepare Inception VM
1. Inception VM - prepare an available Ubuntu VM; we'll create a new one
1. Micro BOSH VM - use BOSH CLI to bootstrap a new VM that is a BOSH (called "Micro BOSH")

That is, by the end of this tutorial you will have two Ubuntu VMs. An Inception VM used to create a BOSH VM. 

NOTE: Both VMs must be in the same IaaS/region because the Inception VM is used to create the private AMI. If you want to deploy a Micro BOSH into different IaaS/regions from the generic stemcell, you also need to create an Inception VM in that IaaS/region.

[sidebar] 

The Inception VM is used to:

* create a private AMI from a generic micro BOSH stemcell
* run a registry of AWS to track provisioned components in AWS
* store a registry of deployed Micro BOSHes
* store log files of BOSH CLI interactions with each Micro BOSH

[/sidebar]

## Create the Inception VM

This is a shared tutorial for creating a special VM that will be used to create & manage BOSHes, and allows you to SSH into BOSH-managed VMs.

Please follow the [Create the Inception VM](aws/create-an-aws-inception-vm.md) tutorial and return here.

## Security Group

The security group for the BOSH VMs will need some TCP ports opened. Using the fog session from the previous section:

``` ruby
connection.security_groups.create name: "microbosh", description: "microboshes"
group = connection.security_groups.get("microbosh")
group.authorize_port_range(25555..25555) # BOSH Director API
group.authorize_port_range(6868..6868)   # Message Bus
group.authorize_port_range(25888..25888) # AWS Registry API
group.authorize_port_range(22..22)       # SSH access
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

On your local machine using fog, provision an elastic public IP in the target infrastructure/region (us-east-1 in this tutorial):

``` ruby
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
address = connection.addresses.create
address.public_ip
"1.2.3.4"
```

The "1.2.3.4" value will replace `IPADDRESS` in the `micro_bosh.yml` below.

Back to the Inception VM... 

Create an AWS keypair and store the `.pem` file. Inside the Inception VM:

```
ACCESS_KEY=XXXXXX
SECRET_ACCESS_KEY=YYYYYY
IP_ADDRESS=1.2.3.4
PASSWORD=somethingmemorable
curl -s https://raw.github.com/drnic/bosh-getting-started/master/scripts/create_keypair > /tmp/create_keypair
chmod 755 /tmp/create_keypair
/tmp/create_keypair aws $ACCESS_KEY $SECRET_ACCESS_KEY us-east-1 microbosh

curl -s https://raw.github.com/drnic/bosh-getting-started/master/scripts/create_micro_bosh_yml > /tmp/create_micro_bosh_yml
chmod 755 /tmp/create_micro_bosh_yml
/tmp/create_micro_bosh_yml microbosh-aws-us-east-1 aws $ACCESS_KEY $SECRET_ACCESS_KEY us-east-1 microbosh microbosh $IP_ADDRESS $PASSWORD
```

This will create a file `microbosh-aws-us-east-1/micro_bosh.yml` that looks as below with the ALLCAPS values filled in. `PASSWORD` above (e.g. 'abc123') will be replaced by the salted version.

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
  vip: IPADDRESS

resources:
  persistent_disk: 4096
  cloud_properties:
    instance_type: m1.small

cloud:
  plugin: aws
  properties:
    aws:
      access_key_id:     ACCESS_KEY_ID
      secret_access_key: SECRET_ACCESS_KEY
      ec2_endpoint: ec2.us-east-1.amazonaws.com
      default_key_name: microbosh
      default_security_groups: ["microbosh"]
      ec2_private_key: /home/vcap/.ssh/microbosh.pem

apply_spec:
  agent:
    blobstore:
      address: IPADDRESS
    nats:
      address: IPADDRESS
  properties:
    aws_registry:
      address: IPADDRESS
```

## Deployment

We now use the BOSH CLI, on the Inception VM, to deploy the Micro BOSH.

```
$ cd /var/vcap/deployments
$ bosh micro deployment microbosh-aws-us-east-1
WARNING! Your target has been changed to `http://1.2.3.4:25555'!
Deployment set to '/var/vcap/deployments/microbosh-aws-us-east-1/micro_bosh.yml'
```

NOTE: To run the `bosh micro deployment microbosh-aws-us-east-1` command you must be in a folder that itself contains a folder `microbosh-aws-us-east-1` that contains `micro-bosh.yml`. In our tutorial, we are in `/var/vcap/deployments` which contains `/var/vcap/deployments/microbosh-aws-us-east-1/micro-bosh.yml`.

Unlike [deploying Micro BOSH using a public AMI](creating-a-micro-bosh-from-ami.md#deployment), when deploying with a generic stemcell we must explicitly download the stemcell to the Inception VM and use it. 

During this process the Inception VM will create a private AMI within the AWS region, and use that AMI to boot the BOSH VM. This means that the BOSH VM and the Inception VM must be in the same IaaS/region/account.

```
$ bosh public stemcells
# confirm that micro-bosh-stemcell-aws-0.6.1.tgz is the latest one
$ bosh download public stemcell micro-bosh-stemcell-aws-0.6.1.tgz
$ bosh micro deploy micro-bosh-stemcell-aws-0.6.1.tgz
WARNING! Your target has been changed to `http://55.55.55.55:25555'!
Deployment set to '/var/vcap/deployments/microbosh-aws-us-east-1/micro_bosh.yml'
Deployed `microbosh-aws-us-east-1/micro_bosh.yml' to `http://1.2.3.4:25555', took 00:17:20 to complete
```

NOTE: You want one called "micro-bosh-stemcell..." rather than a base stemcell with "aws" in its name.

## Elastic IP

Note that above, we expect the IP address to be 1.2.3.4, but `bosh micro deploy` set the target to `55.55.55.55`. Why?

Currently, `bosh micro deploy` does not finish the job [[CF-74](https://cloudfoundry.atlassian.net/browse/CF-74)] with your elastic IP `1.2.3.4`.

We will manually assign the elastic IP to the Micro BOSH VM.

``` ruby
$ fog
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
address = connection.addresses.get('1.2.3.4') # load our elastic IP
server = connection.servers.all('ip-address' => '55.55.55.55').first
address.server = server
```


## Deployment logging

If you want to watch the deployment process in more granular detail, you can tail the log file during deployment.

In another terminal, run:

```
$ ssh ubuntu@ec2-10-9-8-7.compute-1.amazonaws.com
sudo su -

cd /var/vcap/deployments
tail -f microbosh-aws-us-east-1/bosh_micro_deploy.log
```

## Administration

WARNING: There is a default admin user created with a default password "admin". Please change this password immediately.

```
$ bosh create user admin
Enter password: *****************

# or

$ bosh create user admin very-long-and-secure-passphrase
```

Then re-login

```
$ bosh login
Your username: admin
Enter password: *****************
Logged in as 'admin'
```

You can now create user accounts the same way.

## Destroy your Micro BOSH

You can delete a specific Micro BOSH deployment:

```
$ cd /var/vcap/deployments
$ bosh micro deployment microbosh-aws-us-east-1
$ bosh micro delete
```

TODO - will the Micro BOSH delete all its own deployments first?
