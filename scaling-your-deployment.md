# Scaling your deployment

The purpose of booting VMs, attaching disks and wiring up the network is to run jobs. Jobs on the virtual machines. Each job can do a certain amount of work based on the compute resources you've given it. If you need more work done, then you can add more virtual machines or increase the size/attributes of the virtual machines you are using. With BOSH, this is very easy.

NOTE: different jobs can run on the same virtual machine as each other. In the sample release tutorial we put the 3 jobs - nginx, wordpress and mysql on separate virtual machines.

## Introduction to virtual machines on AWS

On AWS, there are a fix set of virtual machines you can use. These are called "instance types". In the example deployment manifest, `wordpress-aws.yml`, we set `instance_type: m1.small` for all three jobs. After we deployed the release, if you looked in your AWS console you would see the 3 additional running VMs.

There are several other [AWS instance types](http://aws.amazon.com/ec2/instance-types/ "Amazon EC2 Instance Types"). They are grouped together as families. For example, `m1.small`, `m1.medium`, `m1.large` and `m1.xlarge` are all in the "Normal" family. Each subsequent member of this family has 2x the CPU, RAM and I/O than its predecessor. 

For example, the `m1.small` has 1.7G of RAM and 1 virtual CPU (VCPU). The next member of the family, the `m1.medium`, has 3.75G of RAM and 2 VCPUS. You want 4 VCPUs and 7.5G of RAM? Then you want the `m1.large`. [AWS pricing](http://aws.amazon.com/ec2/pricing "Amazon EC2 Pricing") also doubles with each increase in instance type. As of writing, `m1.small` is 8c/hr, `m1.medium` is 16c/hr, etc.

If your job requires a different ratio of CPU to RAM, then AWS has two other families of instance types - High CPU and High Memory.

The High CPU family currently has two instance types - the `c1.medium` and `c1.xlarge`. The `c1.medium` is like the `m1.small` with 1.7G of RAM, but has 5 VCPUs, and is only 2x the price of an `m1.small` at 16.5c/hr. 

There currently no `c1.large`. Instead the `c1.xlarge` has 4x the RAM and CPUs of the `c1.medium` and is 4x the price.

The High Memory family currently has three instance types - the `m2.xlarge`, `m2.2xlarge` and `m2.4xlarge`. Each has 2x the CPU, RAM, I/O and price attributes of the former. The `m2.xlarge` offers 17.1G of RAM, only 6.5 VCPUs and costs 45c/hr.

If I/O is your job or entire environments primary bottleneck, then there is the Cluster Compute family of instance types.

In each family of instance types, the largest instance type has the highest I/O. To understand why, imagine how AWS is creating instance types. They take physical hardware - motherboards, CPUs, RAM and an ethernet cable - and virtualize it. The smaller the instance types, the more VMs that the hardware is supporting and the smaller the available I/O is to each VM. If you get the largest VM in a family, then you're getting all the available I/O (probably about 1Gbit) and are not sharing it with anyone.

## Scaling with BOSH

Now that we know all about AWS instance types, let's change our deployment.

* nginx: 1 x m1.small - that should be fine for our evented web server; as traffic scales it might want to grow to gain more I/O
* wordpress: 1 x m1.small to 3 x m1.small - we can scale our wordpress jobs by adding more small instances
* mysql: 1 x m1.small to 1 x m1.xlarge - give our SQL database a healthy combination of high I/O, high RAM and CPU.

That is, we're going to add 2 m1.smalls for wordpress, and upgrade the mysql job to a larger instance type.

This is easy with BOSH. We'll change our `wordpress-aws.yml` deployment manifest, re-run `bosh deploy` and the BOSH director orchestrates everything - from detaching and reattaching disk volumes (to keep our MySQL data safe) to deprovisioning and provisioning new VMs and their static IP addresses.

Make the following changes to your `wordpress-aws.yml` deployment manifest for the `mysql` job:

Add a new `resource_pool` for the special mysql instance:

```yaml
resource_pools:
  - name: common
  ...
  - name: mysql
    network: default
    size: 1
    stemcell:
      name: bosh-stemcell
      version: 0.5.1
    cloud_properties:
      disk: 8192
      instance_type: m1.xlarge
      availability_zone:
      key_name: 
```

Change the `mysql` job to use this new `resource_pool: mysql`. Note that the explicit `instance_type: m1.xlarge` changes too.

```yaml
jobs:
...
  - name: mysql
    template: mysql
    instances: 1
    resource_pool: mysql
    persistent_disk: 16384
    networks:
    - name: default
      default: [dns, gateway]
    cloud_properties:
      instance_type: m1.xlarge
```

Make the following changes for the `wordpress` job. We no longer need a `m1.small` for `mysql`, and need 1 for `nginx` and 3 for `wordpress`, which is 4 `m1.smalls` in total:

```yaml
resource_pools:
  - name: common
    network: default
    size: 4
```

Next, allocate 3 instances (VMs) to `wordpress`.
```yaml
jobs:
...
  - name: wordpress
    template: wordpress
    instances: 3
```

Run `bosh deploy` to confirm the differences and apply the changes:

```
$ bosh deploy

```