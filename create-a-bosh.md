# Create a BOSH

This tutorial shows you how to create your first BOSH for your infrastructure.

In BOSH terminology, we will be creating a Micro BOSH. You will provision a single VM that contains all the parts of BOSH.

This tutorial will take you through the steps related to preparation, creating the configuration file and using the BOSH CLI to deploy the Micro BOSH VM.

We will use a tool called [bosh-bootstrap](https://github.com/StarkAndWayne/bosh-bootstrap) that makes it very easy to boot up and maintain each Micro BOSH that you need. 

## What will happen in this tutorial

There are three servers being referenced in this tutorial, in addition to your local machine, we will create two servers:

1. Local server
1. Inception server - use an existing Ubuntu server; or create a new one
1. Micro BOSH server - use the Inception VM to unpack a pre-made stemcell to boot a Micro BOSH server

That is, by the end of this tutorial you will have two Ubuntu servers. An Inception server which is used to create a BOSH server. 

NOTE: For AWS, servers must be in the same IaaS/region because the Inception VM is used to create the private AMI. If you want to deploy a Micro BOSH into different IaaS/regions from the generic stemcell, you also need to create an Inception VM in that IaaS/region.

For AWS, the Inception server is used to:

* create a private AMI from a pre-package micro BOSH stemcell
* run a registry to track provisioned components (for AWS and OpenStack)
* store a registry of deployed Micro BOSHes
* store log files of BOSH CLI interactions with each Micro BOSH

For OpenStack, the Inception server is used to:

* create a custom micro BOSH stemcell
* create an OpenStack image from the custom micro BOSH stemcell
* run a registry of OpenStack to track provisioned components in OpenStack
* store a registry of deployed Micro BOSHes
* store log files of BOSH CLI interactions with each Micro BOSH

## Prerequisites

Check below for the prerequisites for your infrastructure, before getting started.

Locally, you will need Ruby 1.8+ installed and access to the Internet thing. As an inline sidebar, you won't need huge amounts of local bandwidth - all large file transfers are done into/out-of the Inception server rather than your local machine.

If you've never created SSH keys before, run the following command on your local server to create `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` files:

```
$ ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
```

### AWS

You'll need an Amazon AWS account and API access/secret credentials that can read/write EC2 and S3.

### OpenStack

You'll need an [OpenStack Essex (2012.1)](http://openstack.org/software/essex/) installation.

If you have access to a unused baremetal server, you can build a complete OpenStack environment using these resources:

* [DevStack](http://devstack.org/)
* [hastexo! tutorial](http://www.hastexo.com/resources/docs/installing-openstack-essex-20121-ubuntu-1204-precise-pangolin)

Once you've installed and tested your OpenStack box, you'll need to [upload](http://docs.openstack.org/developer/glance/glance.html#examples-of-uploading-different-kinds-of-images) an [Ubuntu 10.04 LTS 64-bit image](http://uec-images.ubuntu.com/lucid/current/) before proceeding with the next steps.

## Tutorial

We will use the very helpful [bosh-bootstrap](https://github.com/StarkAndWayne/bosh-bootstrap) tool from [Stark & Wayne](http://starkandwayne/) that prompts and automates your way through everything to create your Inception and Micro BOSH servers.

To install the tool:

```
$ gem install bosh-bootstrap
```

When you run the tool, it will initially prompt you for choices. On subsequent runs it will remember the previous choices.

As an example, to deploy your Inception and Micro BOSH servers into AWS us-east-1 region.

When you first run it it will ask what infrastructure provider to use and credentials. If you've ever used fog before, it will look in your local `~/.fog` file to make the bootstrap process even faster. If you don't have a `~/.fog` file then you will select "Alternate credentials" to choose an infrastructure and provide API credentials.

```
$ bosh-bootstrap

Stage 1: Choose infrastructure

Found infrastructure API credentials at /Users/drnic/.fog (override with --fog)
1. AWS (default)
2. Alternate credentials
Choose infrastructure:  1
Confirming: Using infrastructure provider AWS
```

Next, based on the target infrastructure (for example, public AWS or your private OpenStack) you may be prompted for a specific region or datacenter:

```
1. ap-northeast-1
2. ap-southeast-1
3. eu-west-1
4. sa-east-1
5. us-east-1
6. us-west-1
7. us-west-2
Choose AWS region:  5
Confirming: Using AWS region us-east-1
```

```
Stage 2: BOSH configuration

Useful name for Micro BOSH?  |microbosh-aws-us-east-1|  
Confirming: Micro BOSH will be named microbosh-aws-us-east-1

Please enter a user/password for the BOSH that will be created.
BOSH username: |drnic|
BOSH password: xxxxxxxx
Confirming: After BOSH is created, your username will be drnic

Defaulting to 16Gb persistent disk for BOSH
Acquiring IP address for micro BOSH...
Confirming: Micro BOSH will be assigned IP address 23.21.53.241

opened port 22 in security group microbosh-aws-us-east-1
opened port 6868 in security group microbosh-aws-us-east-1
opened port 25555 in security group microbosh-aws-us-east-1
opened port 25888 in security group microbosh-aws-us-east-1
Confirming: Micro BOSH protected by security group named microbosh-aws-us-east-1, with ports [22, 6868, 25555, 25888]

creating key pair microbosh-aws-us-east-1...
Confirming: Micro BOSH accessible via key pair named microbosh-aws-us-east-1

Locating micro-bosh stemcell, running 'bosh public stemcells --tags micro,aws,stable'...
Confirming: Micro BOSH will be created with stemcell micro-bosh-stemcell-aws-0.6.4.tgz


Stage 3: Create/Allocate the Inception VM

1. create new inception VM
2. use an existing Ubuntu server
3. use this server (must be ubuntu & on same network as bosh)
Create or specify an Inception VM:  1

Provisioning m1.small for inception VM...
Provisioning IP address for inception VM...
Provisioning 16Gb persistent disk for inception VM...
Mounting persistent disk as volume on inception VM...
Confirming: Inception VM has been created

SSH access: ssh -i /Users/drnic/.ssh/id_rsa ubuntu@ec2-23-21-54-203.compute-1.amazonaws.com
Confirming: Using inception VM ubuntu@ec2-23-21-54-203.compute-1.amazonaws.com

validating ubuntu
uploading /tmp/remote_script_validate_ubuntu to Inception VM
Successfully validated ubuntu

Stage 4: Preparing the Inception VM

```