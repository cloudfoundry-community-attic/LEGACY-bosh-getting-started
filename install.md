These instructions are a combination of "Boot an AWS instance" and "Install BOSH via its chef_deployer"

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

From Wesley's [fog blog post|http://www.engineyard.com/blog/2011/spinning-up-cloud-compute-instances/], boot a vanilla Ubunutu 64-bit image:

```
$ fog
  Welcome to fog interactive!
  :default provides AWS and VirtualBox
connection = Fog::Compute.new({:provider => 'AWS'})
server = connection.servers.bootstrap({
  :public_key_path => '~/.ssh/id_rsa.pub',
  :private_key_path => '~/.ssh/id_rsa',
  :username => 'ubuntu'
})
```

Or a big instance type to make everything go faster:

```
server = connection.servers.bootstrap({
  :public_key_path => '~/.ssh/id_rsa.pub',
  :private_key_path => '~/.ssh/id_rsa',
  :flavor_id => 'c1.xlarge', # 64 bit, high CPU
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
address.public_ip
"107.21.120.243"
```

## Firewall/Security Group

FIXME/CHECK

You need to open ports 80 and 9022 to Internet. For AWS your Security Group will look like:

![security groups](https://img.skitch.com/20111212-nj6grrj6utrh9rx6qgcede75pp.png)

## Install Cloud Foundry

These commands below can take a long time. If it terminates early, re-run it until completion.

Alternately, run it inside screen or tmux so you don't have to fear early termination:

```
$ ssh ubuntu@107.21.120.243
# sudo apt-get install screen -y
# screen
sudo apt-get update
sudo apt-get install git-core build-essential libsqlite3-dev curl \
libmysqlclient-dev libxml2-dev libxslt-dev libpq-dev -y

git clone git://github.com/sstephenson/rbenv.git .rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
tar xvfz ruby-1.9.2-p290.tar.gz
cd ruby-1.9.2-p290
./configure --prefix=$HOME/.rbenv/versions/1.9.2-p290
make
make install

cd
source ~/.bashrc
rbenv global 1.9.2-p290
gem update --system
gem install bundler rake
rbenv rehash

   
git clone https://github.com/cloudfoundry/bosh.git
cd bosh/chef_deployer
bundle
bundle exec bin/chef_deployer 