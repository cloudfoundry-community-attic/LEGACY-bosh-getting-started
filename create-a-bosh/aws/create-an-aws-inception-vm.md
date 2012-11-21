# Create the Inception VM for AWS

This is a shared tutorial for creating a special VM that will be used to create & manage BOSHes, and allows you to SSH into BOSH-managed VMs.

We will use fog to create the first Ubuntu VM on AWS. You could alternately create one any way that you want, see [not using fog?](../../details/not-using-fog.md) for suggestions. In the next section we will prepare the VM with all the packages and source required for deploying a BOSH VM.

### Setup

In this tutorial we're going to use a command-line program called [fog](http://fog.io) to create our Inception VM, and then later on for provisioning an elastic IP address for the BOSH VM.

Three setup steps to run on your local machine:

1. Create SSH keys
1. Install fog
1. Create `.fog` credentials file (with your [AWS API credentials](https://portal.aws.amazon.com/gp/aws/securityCredentials))

If you've never created SSH keys before, run the following command to create `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` files:

```
$ ssh-keygen
```


Create a `~/.fog` credentials file:

```
:default:
  :aws_access_key_id:     PERSONAL_ACCESS_KEY
  :aws_secret_access_key: PERSONAL_SECRET
```

Install latest version of fog and run the interactive console:

```
$ gem install fog
$ fog
  Welcome to fog interactive!
  :default provides AWS and VirtualBox
```

### Boot Ubuntu instance

From Wesley's [fog blog post](http://www.engineyard.com/blog/2011/spinning-up-cloud-compute-instances/ "Spinning Up Cloud Compute Instances | Engine Yard Blog"), boot a vanilla Ubuntu 64-bit image in `us-east-1` region, with a new elastic IP:

``` ruby
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
server = connection.servers.bootstrap({
  :public_key_path => '~/.ssh/id_rsa.pub',
  :private_key_path => '~/.ssh/id_rsa',
  :flavor_id => 'm1.small',
  :bits => 64,
  :username => 'ubuntu'
})
address = connection.addresses.create
address.server = server
server.reload
server.dns_name
```

This DNS name, for example `ubuntu@ec2-10-9-8-7.compute-1.amazonaws.com`,	 will be used later to SSH into our Inception VM.

You can check that SSH key credentials are setup. The following should return "ubuntu" and shouldn't timeout.

```
server.ssh("whoami").first.stdout
"ubuntu"
```

Our Inception VM will store the configuration and deployment details of our Micro BOSH VMs. So we want to ensure all data is persistent beyond the lifespan of the Inception VM itself. In AWS, we use EBS volumes. We will construct the Inception VM in the manner that BOSH itself constructs VMs and attach a volume at the `/var/vcap/store` mount point.


``` ruby
# Create/attach a volume at /dev/sdi (or somewhere free)
volume = connection.volumes.create(:size => 16, :device => "/dev/sdi", :availability_zone => server.availability_zone)
volume.server = server

# Format and mount the volume
server.ssh(['sudo mkfs.ext4 /dev/sdi -F']) 
server.ssh(['sudo mkdir -p /var/vcap/store'])
server.ssh(['sudo mount /dev/sdi /var/vcap/store'])
puts server.ssh(['df']).first.stdout
```

You will now view the mounted 16G volume at `/var/vcap/store`:

```
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/sda1              8256952    740388   7097136  10% /
none                    830428       120    830308   1% /dev
none                    880720         0    880720   0% /dev/shm
none                    880720        48    880672   1% /var/run
none                    880720         0    880720   0% /var/lock
none                    880720         0    880720   0% /lib/init/rw
/dev/sdb             153899044    192068 145889352   1% /mnt
/dev/sdi               5160576    141304   4757128   3% /var/vcap/store
```

If you see `No such file or directory while trying to determine filesystem size`, then wait a moment for the EBS volume to be mounted and run the `server.ssh` commands again.

If you get `Errno::ETIMEDOUT: Operation timed out - connect(2)` errors, please create a ticket to let me know. I got them sometimes. Perhaps wait a moment and try again. You can also run these shell commands directly from within the SSH session later.

## Preparation

We now need to prepare our Ubuntu VM with the source code to be able to run the Micro BOSH deployment command.

These steps come from the [BOSH documentation](https://github.com/cloudfoundry/oss-docs/blob/master/bosh/documentation/documentation.md#bosh-deployer).

```
$ ssh ubuntu@ec2-10-9-8-7.compute-1.amazonaws.com
sudo su -

export ORIGUSER=ubuntu
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
