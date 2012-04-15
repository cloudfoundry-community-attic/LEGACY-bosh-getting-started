# Deploying the sample release

At the time of writing, there are 4 example BOSH releases. Below is the list and what you deploy with them:

* [cloudfoundry/bosh-sample-release](https://github.com/cloudfoundry/bosh-sample-release) - nginx, wordpress & mysql
* [cloudfoundry/cf-release](https://github.com/cloudfoundry/cf-release) - Cloud Foundry
* [cloudfoundry/oss-release](https://github.com/cloudfoundry/oss-release) - Gerret & Jenkins as [used by CloudFoundry](http://reviews.cloudfoundry.org/ "Gerrit Code Review")
* [cloudfoundry/bosh-release](https://github.com/cloudfoundry/bosh-release) - BOSH itself (inception!)

In this tutorial you will deploy the sample release. It is a 3-tier LAMP application: a wordpress blog which consists of a number of apache servers running php & wordpress, fronted by nginx, and using one mysql database for storage.

## Get the release code

You can get the sample release project using normal `git clone` or using the `gerrit clone` if you think you'll be contributing to the repository:

```
git clone https://github.com/cloudfoundry/bosh-sample-release.git

or

gerrit clone ssh://reviews.cloudfoundry.org:29418/bosh-sample-release.git
```

## Networking provisioning

BOSH can provision VMs and disks. The Deployment Manifest will describe how many VMs/disks are required. BOSH & the deployment manifest cannot provision "an elastic IP address". Rather, IP addresses must be pre-provisioned and known in advance.

Currently, until BOSH adds DNS support, you'll need IP address per VM that BOSH manages. BOSH can provision and deprovision VMs on its own; yet you need to pre-provision the IP addresses.

In AWS, that's one Elastic IP per managed VM. BOSH will manage the attachment of the IPs to the VMs. You will tell BOSH about the Elastic IPs in your deployment manifest later.

Let's create some with fog into the AWS region that you will be deploying your sample release. These Elastic IPs are different from the one [created with your BOSH](creating-a-bosh-from-scratch.md).

```
$ fog
  Welcome to fog interactive!
  :default provides AWS and VirtualBox
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
addresses = (1..3).map {|i| connection.addresses.create}
addresses.map(&:public_ip)
["23.23.10.11", "23.23.10.12", "23.23.10.13"]
```

Write those down on a Post-it note. You'll need them later.

FIXME - find some stupid Post-it notes and insert a picture. This FIXME is not as funny as a real picture of a post-it note.

### AWS Elastic IPs are scarce

So far in the tutorial we've created 4 Elastic IPs (one for the BOSH and three for this sample release) in the us-east-1 region.

AWS accounts initially restrict each region to 5 Elastic IP addresses. In current BOSH that limits you to 5 VMs per region, which isn't very many. You can [Request to Increase Elastic IP Address Limit](http://aws.amazon.com/contact-us/eip_limit_request/ "Request to Increase Elastic IP Address Limit") and AWS will reply within a few days. 

Perhaps when AWS support IPv6 for Elastic IPs they won't be such a scare resource anymore. 

Better still, when BOSH includes its own DNS then it won't need public Elastic IPs to be able to reference each of the VMs. You'll just need Elastic IPs for any real, public IPs that your deployed environment actually requires. You know, for getting traffic from your customers.


