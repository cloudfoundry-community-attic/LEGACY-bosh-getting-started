These instructions are a combination of "Boot an AWS instance" and "Install BOSH via its chef_deployer"

**NOTE: This instructions are for review only. I'll write them up as a formal blog post soon. Thanks for your help!**


* Create a VM
* Run prepare_instance.sh inside instance
* Use chef_deployer to setup the VM as BOSH

## Setup

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

## Boot instance

From Wesley's [fog blog post](http://www.engineyard.com/blog/2011/spinning-up-cloud-compute-instances/ "Spinning Up Cloud Compute Instances | Engine Yard Blog"), boot a vanilla Ubunutu 64-bit image:

```
$ fog
  Welcome to fog interactive!
  :default provides AWS and VirtualBox
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
server = connection.servers.bootstrap({
  :public_key_path => '~/.ssh/id_rsa.pub',
  :private_key_path => '~/.ssh/id_rsa',
  :flavor_id => 'm1.large', # 64 bit, normal large
  :username => 'ubuntu'
})
```

Check that SSH key credentials are setup. The following should return "ubuntu", and shouldn't timeout.

```
server.ssh "whoami"
```

Now create an elastic IP and associate it with the instance. (I did this via the console).

```
address = connection.addresses.create
address.server = server
server.reload
server.dns_name
"ec2-10-2-3-4.compute-1.amazonaws.com"
```

**The public DNS name will be used in the remainder of the tutorials to reference the BOSH VM.**

## Firewall/Security Group

Go to the [AWS console](https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups) and set your Security Group "Inbound" to include the 25555 port: (the default BOSH director port)

![security groups](https://img.skitch.com/20120414-m9g6ndg3gfjs7kdqhbp2y9a6y.png)

## Install Cloud Foundry

These commands below can take a long time. If it terminates early, re-run it until completion.

Alternately, run it inside screen or tmux so you don't have to fear early termination:

```
$ ssh ubuntu@ec2-10-2-3-4.compute-1.amazonaws.com
sudo su -
groupadd vcap 
useradd vcap -m -g vcap

mkdir -p /var/vcap/
cp /home/ubuntu/.ssh/authorized_keys /var/vcap/

vim /etc/apt/sources.list
```

Add the following line:

```
deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ lucid multiverse
```

Back in the terminal:

```
apt-get update
apt-get install git-core -y
cd /tmp
git clone https://github.com/cloudfoundry/bosh.git
cd bosh/release/template/instance
./prepare_instance.sh
chmod 777 /var/vcap/deploy

exit
```

**From another terminal on your local machine:**

Make a copy of the `examples/microbosh` folder and add your AWS credentials as appropriate into `config.yml`:

```
cd /tmp
git clone git://github.com/drnic/bosh-getting-started-on-aws.git
cd bosh-getting-started-on-aws/examples/microbosh
vim config.yml
```

* replace all `PUBLIC_DNS_NAME` with your fog-created VM's `server.dns_name` (e.g. ec2-10-2-3-4.compute-1.amazonaws.com)
* replace `ACCESS_KEY_ID` with your AWS access key id
* replace `SECRET_ACCESS_KEY` with your AWS secret access key

In VIM, you can "replace all" by typing:

```
:%s/PUBLIC_DNS_NAME/ec2-10-2-3-4.compute-1.amazonaws.com/g
```



```
cd /tmp
git clone https://github.com/cloudfoundry/bosh.git
cd bosh/chef_deployer
bundle
cd ../release/
ruby ../chef_deployer/bin/chef_deployer deploy /tmp/bosh-getting-started-on-aws/examples/microbosh
...lots of chef...
```

We can now connect to our BOSH!

```
$ bosh target ec2-10-2-3-4.compute-1.amazonaws.com:25555
Target set to 'yourboshname (http://ec2-10-2-3-4.compute-1.amazonaws.com:25555) Ver: 0.4 (1e5bed5c)'
Your username: admin
Enter password: *****
Logged in as 'admin'
```

Username/password was configured as admin/admin unless you changed it.

Yay!