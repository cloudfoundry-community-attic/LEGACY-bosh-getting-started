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


