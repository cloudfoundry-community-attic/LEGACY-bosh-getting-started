# Upgrade a microbosh using a new stemcell

When a new microbosh stemcell is available, it is very simple to upgrade each of your microboshes. It takes around 30 minutes, with about 15 minutes of downtime for your microbosh.

NOTE: the `bosh-stemcell-aws-0.6.7.tgz` mentioned below is not the latest stemcell to work with `micro-bosh-stemcell-aws-0.7.0.tgz` - there is a `bosh-stemcell-aws-0.6.7b.tgz` that is available for private testing; and a newer stemcell will be released to go with microbosh 0.7.0 when it is ready.

## Download new microbosh stemcell

To see if there is a new stable microbosh stemcell:

```
$ bosh public stemcells --tags micro
+-----------------------------------------+------------------------+
| Name                                    | Tags                   |
+-----------------------------------------+------------------------+
| micro-bosh-stemcell-0.1.0.tgz           | vsphere, micro         |
| micro-bosh-stemcell-aws-0.6.4.tgz       | aws, micro, stable     |
| micro-bosh-stemcell-aws-0.7.0.tgz       | aws, micro, test       |
| micro-bosh-stemcell-openstack-0.7.0.tgz | openstack, micro, test |
| micro-bosh-stemcell-vsphere-0.6.4.tgz   | vsphere, micro, stable |
| micro-bosh-stemcell-vsphere-0.7.0.tgz   | vsphere, micro, test   |
+-----------------------------------------+------------------------+
To download use `bosh download public stemcell <stemcell_name>'. For full url use --full.
```

So you don't get confused, if our microbosh is on AWS, to filter out all other stemcells:

```
$ bosh public stemcells --tags micro,aws
+-----------------------------------+--------------------+
| Name                              | Tags               |
+-----------------------------------+--------------------+
| micro-bosh-stemcell-aws-0.6.4.tgz | aws, micro, stable |
| micro-bosh-stemcell-aws-0.7.0.tgz | aws, micro, test   |
+-----------------------------------+--------------------+
To download use `bosh download public stemcell <stemcell_name>'. For full url use --full.
```

Note "stable" tag means that the stemcell is deemed "good" by the BOSH core team. Other stemcells may be in development or testing. Buyer beware!

Consider that we have an AWS microbosh was built from stable stemcell `micro-bosh-stemcell-aws-0.6.4.tgz` or its equivalent AWS AMI. Then we will download and use the unstable `micro-bosh-stemcell-aws-0.7.0.tgz`.

If on vsphere or openstack, then choose the appropriate tag filter above.

Downlaod the new stemcell.

```
$ cd /tmp
$ bosh download public stemcell micro-bosh-stemcell-aws-0.7.0.tgz
```

## Upgrade your microbosh

Change to the microbosh deployments folder, select the microbosh to upgrade and perform the upgrade!

```
$ cd /var/vcap/deployments
$ bosh micro deployment microbosh-aws-us-east-1
$ bosh micro deploy /tmp/micro-bosh-stemcell-aws-0.7.0.tgz --update
Updating micro BOSH instance `microbosh-aws-us-east-1/micro_bosh.yml' to `microbosh-aws-us-east-1' (type 'yes' to continue): yes

Verifying stemcell...
File exists and readable                                     OK
Manifest not found in cache, verifying tarball...
Extract tarball                                              OK
Manifest exists                                              OK
Stemcell image file                                          OK
Writing manifest to cache...
Stemcell properties                                          OK

Stemcell info
-------------
Name:    micro-bosh-stemcell
Version: 0.7.0


Prepare for update
  stopping agent services (00:00:01)                                                                
  unmount disk (00:00:07)                                                                           
  detach disk (00:00:12)                                                                            
  delete VM (00:00:32)                                                                              
  preserving stemcell (00:00:00)                                                                    
Done                    5/5 00:00:53                                                                

Deploy Micro BOSH
  unpacking stemcell (00:00:13)                                                                     
  uploading stemcell (00:10:20)                                                                     
  creating VM from ami-da1ea4b3 (00:00:26)                                                          
  waiting for the agent (00:03:11)                                                                  
  mount disk (00:00:03)                                                                             
  stopping agent services (00:00:01)                                                                
  applying micro BOSH spec (00:00:35)                                                               
  starting agent services (00:00:00)                                                                
  waiting for the director (00:01:59)                                                               
Done                    11/11 00:16:57                                                              
Deployed `microbosh-aws-us-east-1/micro_bosh.yml' to `microbosh-aws-us-east-1', took 00:17:51 to complete
```

## Newer bosh stemcells

Now that you've upgraded your bosh, it may be able to support newer stemcells for your bosh releases.

From the `bosh public stemcells --tags all` list above, we see there is a `bosh-stemcell-aws-0.6.7.tgz` stemcell.

Download it and upload to the upgraded microbosh. Your releases will then be able to be upgraded.

```
$ cd /tmp
$ bosh download public stemcell bosh-stemcell-aws-0.6.7.tgz
$ bosh upload stemcell bosh-stemcell-aws-0.6.7.tgz
```

In your bosh deployment manifests, you can now upgrade to the new stemcell. For example:

```
...
resource_pools:
- name: common
  network: default
  size: 1
  stemcell:
    name: bosh-stemcell
    version: 0.6.7 # CHANGED HERE!
  cloud_properties:
    instance_type: m1.small
  persistent_disk: 16196
...
```