# Creating a new stemcell

If you are on a new IaaS and/or if there isn't a public stemcell for your architecture (at the time of writing the only non-vSphere public stemcell, is `bosh-stemcell-aws-0.5.1.tgz` which is for 64-bit AWS), then you will need to create a base stemcell for your environment VMs.

If you want your environment VMs to boot faster - by not having to install packages - you can also create a custom stemcell that includes all the packages you need.

## Creating a stemcell

**TODO - write this tutorial**

Boot up a big 64-bit VM. You only use 64-bit AWS instances now, right?

SSH into your MicroBOSH Ubuntu instance.

```
sudo su -
apt-get install debootstrap

```

You'll need ovftool from VMWare. Go here http://www.vmware.com/support/developer/ovf/, agree to the agreement. Then:

* Click "Use Web Browser" checkbox
* Then get the URL for the .bundle file for Linux 64-bit
* Download it to your VM

```
wget 'http://www.vmware.com/downloads/downloadBinary.do?downloadGroup=OVF-TOOL-2-1&vmware=downloadBinary&file=VMware-ovftool-2.1.0-467744-lin.x86_64.bundle&pot=1&code=VMware-ovftool-2.1.0-467744-lin.x86_64.bundle&hashKey=6d25dd07be852e2adace7b016394e189&tranId=70855849&downloadURL='
```


cd /var/vcap/deploy/bosh/director/current/agent/misc/
gem install bundler
bundle