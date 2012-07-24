# Create and deploy a new release

You can quickly create the initial scaffold for a new release using the 3rd-party `bosh-gen` tool (ok, to be fair, Dr Nic wrote it).

Install the tool using RubyGems, then create a new release with `bosh-gen new`:

```
$ gem install bosh-gen

$ mkdir -p ~/.bosh_deployments/redis-on-demand
$ cd ~/.bosh_deployments/redis-on-demand

$ bosh-gen new redis-on-demand

$ cd redis-on-demand
```

This will generate the scaffold for the release in a folder `~/.bosh_deployments/redis-on-demand/redis-on-demand`. Later we will put the one or more deployment manifest files in the parent folder `~/.bosh_deployments/redis-on-demand`.

The generated project will also be converted into a Git repository. If you don't want this, then delete the `~/.bosh_deployments/redis-on-demand/redis-on-demand/.git` folder .

## Packages built from original source

```
$ bosh-gen package redis
      create  packages/redis/packaging
      create  packages/redis/pre_packaging
      create  packages/redis/spec
```

The initial `spec` manifest shows below that this package requires no files and has no dependencies on any other packages.

```yml
$ cat packages/redis/spec
---
name: redis
dependencies: []
files: []
```

If we were to attempt to create a release now, we'll see that BOSH requires that packages all require one or more source files.

```
$ bosh create release --force
...

Building packages
-----------------
Error 500: Package 'redis' doesn't include any files
```

Let's add some redis source code to the redis package! (link comes from [redis downloads page](http://redis.io/download "Download – Redis"))

```
$ bosh-gen source redis http://redis.googlecode.com/files/redis-2.4.13.tar.gz
Downloading http://redis.googlecode.com/files/redis-2.4.13.tar.gz...
...
       force  packages/redis/spec
      create  src/redis/redis-2.4.13.tar.gz
```

The redis package spec is now updated to reference the source tarball.

```yaml
$ cat packages/redis/spec
---
name: redis
dependencies: []
files:
- redis/redis-2.4.13.tar.gz
```

We now have a valid release (albeit, without any jobs that will require our redis package)

```
$ bosh create release --force
...
Packages
+-------+---------+-------------+------------------------------------------+
| Name  | Version | Notes       | Fingerprint                              |
+-------+---------+-------------+------------------------------------------+
| redis | 0.1-dev | new version | aa3d5904ca4fbc49a13b71a98e44d0660abf905f |
+-------+---------+-------------+------------------------------------------+
...
Release version: 1
Release manifest: .../dev_releases/redis-on-demand-1.yml
```

## Packaging a package source

Packages are compiled on demand during the deployment. This process is completely automated by BOSH. How it works and how compilation is triggered will be discussed later. In this section, we need to tell BOSH how to compile the redis source code into binary executables. These compiled executables will be automatically available during deployment on all VMs that need it. 

Each package has two executable hooks that are run during the package compilation process

* `pre_packaging` - run when the source of the package is assembled during the `bosh create release` (in developer environment)
* `packaging` - compilation process run during deployment (in a clean stemcell VM)

For the redis package, only the `packaging` script is necessary. Copy the following into `packages/redis/packaging`. If you are using a more modern redis download, then replace `2.4.13` below with your version number.

```bash
tar zxf redis/redis-2.4.13.tar.gz

if [[ $? != 0 ]] ; then
  echo "Failed extracting redis"
  exit 1
fi

(
  cd redis-2.4.13
  make
  make PREFIX=$BOSH_INSTALL_TARGET install
)
```

Note `PREFIX=$BOSH_INSTALL_TARGET` above. All `packaging` scripts must place their compiled outputs in a specific folder that BOSH determines. This folder location is provided by the `$BOSH_INSTALL_TARGET` environment variable. Only the contents of this folder are used as the "compiled package", and only the contents of this folder will be installed into the VMs during deployment.

This is different from many other packaging systems which assume that they can install files anywhere on the file system. In BOSH, packages can only manage files within a specific subfolder. This ensures clean separation of all packages and all versions of the same package.

At this time in the tutorial, it is not yet possible to test our packaging scripts in isolation. Package compilation is performed automatically during deployment. Deployment of a package requires a deployment manifest and one or more jobs that use the package. 

Let's wire up the redis job and a simple deployment manifest now.

## Starting processes or jobs

We can now install redis, but we cannot yet run redis (specifically we care about `redis-server`). How to start or stop a process is described by a job. In fact, packages are only installed on VMs during deployment if they are required directly or indirectly by the job assigned to that VM.

To create a redis job that requires the redis package:

```
$ bosh-gen job redis -d redis
      create  jobs/redis
      create  jobs/redis/TODO.md
      create  jobs/redis/monit
      create  jobs/redis/templates/redis_ctl
       chmod  jobs/redis/templates/redis_ctl
      create  jobs/redis/spec
Next step for redis job:

* Replace "`exec /var/vcap/packages/redis/bin/EXECUTABLE_SERVER`" in jobs/redis/templates/redis_ctl

```

Jobs each have a spec file of their dependencies and of templates/files that they want to be created during deployment.

```yml
$ cat jobs/redis/spec 
---
name: redis
packages:
- redis
templates:
  redis_ctl: bin/redis_ctl
```

We need to update the initial `redis_ctl` script to tell the job how to start the `redis-server` command.

Replace the start of the following line:

```bash
exec /var/vcap/packages/redis/bin/EXECUTABLE_SERVER 
```

with

```bash
exec /var/vcap/packages/redis/bin/redis-server
```

NOTE: keep the remainder of the line that stores the `STDOUT` and `STDERR` pipes into log files.

It happens that `redis-server` can take configuration via its first argument. We will set up the configuration and pass properties from the deployment manifest later. For the moment, we will run redis using all its defaults.

The control script `redis_ctl` also determines where STDOUT and STDERR from the redis job will go. From the template, we will be able to find the log files at `/var/vcap/sys/log/redis` on any redis job VM.

We are not done yet. As it stands, when redis-server is run we are not storing the process ID (PID) anywhere. The PID is necessary so that the job process can be stopped and restarted.

How a process generates a PID and returns it to the control script can vary. For `redis-server` we can tell it where to store a PID via a configuration file.

First, let's finish the `redis_ctl` script and tell it to use a `redis.conf` file, which will in turn tell it where to store the PID value. Next, we will generate the `redis.conf` file from our job.

Change the lines we created above

```bash
exec /var/vcap/packages/redis/bin/redis-server ...
```

with

```bash
exec /var/vcap/packages/redis/bin/redis-server /var/vcap/jobs/redis/config/redis.conf ...
```

The control script now expects that there will be a `redis.yml` file. Our redis job is responsible for creating it.

In the release, create a new template file:

```
$ bosh-gen template redis config/redis.conf
      create  jobs/redis/templates/redis.conf.erb
       force  jobs/redis/spec
```

The redis job spec is updated to put the generated `redis.conf` into the `config/` folder. When BOSH deploys the job, this will be at `/var/vcap/job/redis/config/redis.conf`; just as we provided to the `redis-server` in the `redis_ctl` above.

Initially, `redis.conf.erb` is blank. Populate it with the following redis configuration:

```
daemonize no
pidfile /var/vcap/sys/run/redis/redis.pid
timeout 300
loglevel notice
logfile stdout
databases 16
dir /var/vcap/store/redis
maxclients 0
maxmemory-policy noeviction
save 60 1000
appendonly yes
```

For redis, we can tell it where to store its PID via the `pidfile` config value. The value provided `/var/vcap/sys/run/redis/redis.pid` matches the value of `$PIDFILE` in `jobs/redis/templates/redis_ctl`.

## Upload our release to BOSH

Before deploying a new or updated release, we must upload the latest version to BOSH.

First, commit our release repository changes and create a new release:

```
$ git add .
$ git commit -m "added redis package & job"
$ bosh create release
...
Release version: 2
...
```

Now upload the latest release to your BOSH:

```
$ bosh upload release
...
Release info
------------
Name:    redis-on-demand
Version: 2
...
Creating new packages
  redis/0.2-dev (00:00:00)                                                                          
Done                    1/1 00:00:00                                                                

Creating new jobs
  redis/0.1-dev (00:00:00)                                                                          
Done                    1/1 00:00:00
...
```

There are three concepts in our redis release and hence three release numbers being show above.

* release "redis-on-demand" is at version 2
* package "redis" is at version 0.2
* job "redis" is at version 0.1

If we change the contents of a job or a package then those jobs/packages increase their version number, and the release number increases.

You may notice the "dev" suffix. We will discuss "dev" and "final" releases later.

## Deploying our release

To deploy Redis we need the final component of the trio: the deployment manifest. As a reminder, the trio are:

* stemcell
* release
* deployment manifest

A deployment manifest needs the unique id (UUID) of our BOSH Director to ensure it is always targeting the correct BOSH:

```
$ bosh status | grep UUID                                                                                  
UUID           c897319f-9b4b-41ae-9ed7-XXXXXXX
```

We can now create a deployment manifest based on the redis release we have created in this tutorial.

```
$ cd ~/.bosh_deployments/redis-on-demand
$ bosh-gen manifest redis-dev redis-on-demand c897319f-9b4b-41ae-9ed7-XXXXXXX
      create  redis-dev.yml
```

The three arguments being passed to `bosh-gen manifest` are, in order:

1. Deployment name (also the manifest file name)
1. Path to the release project
1. BOSH Director UUID

The remaining information required for a default deployment manifest is determined from the release project, such as the list of jobs and the latest release information.

```
$ cat redis-dev.yml
---
name: redis-dev
director_uuid: c897319f-9b4b-41ae-9ed7-XXXXXXX
release:
  name: redis-on-demand
  version: 2
...
jobs:
- name: redis
  template: redis
  instances: 1
  resource_pool: common
  networks:
  - name: default
    default:
    - dns
    - gateway
properties: {}
```

To deploy our release, change into the release folder, run `bosh deploy` and type `"yes"` as requested:

```
$ cd redis-on-demand
$ bosh deploy
```

First it will validate your deployment manifest against the releases that your BOSH knows about. It will find "redis-on-demand version 2", since we previously uploaded it.

It will appear to pause at the following:

```
Compiling packages
redis/0.2-dev         |                        | 0/1 00:01:59  ETA: --:--:--          
```

Wait patiently a few minutes. BOSH is automatically compiling your redis source code into redis binary executables, including `redis-server`. It does this with a new, clean VM; and then destroys the VM when it is completed. If you have a release with 40 packages, then 40 VMs will be used. This ensures that each package is built in a clean environment, with only its own dependencies available.

The terminal will then change to show that VMs are being booted to run the redis job:

```
Compiling packages
  redis/0.2-dev (00:03:20)                                                                          
Done                    1/1 00:03:20                                                                

Preparing DNS
  binding DNS (00:00:00)                                                                            
Done                    1/1 00:00:00                                                                

Creating bound missing VMs
common/0              |                        | 0/1 00:00:55  ETA: --:--:--
```

Initially VMs are booted into resource pools (based on the stemcell). Next they are converted into a job, which includes installing the pre-compiled packages that the job needs.

For our redis release, we will boot a single VM into a resource pool called "common", and it is assigned to a single instance of the redis job.

In progress...

```
Updating job redis
redis/0 (canary)                    |oooooooooooooooooooo    | 0/1 00:00:30  ETA: --:--:--
```

Complete!

```
...
Updating job redis
  redis/0 (canary) (00:00:41)                                                                       
Done                    1/1 00:00:41                                                                

Task 73: state is 'done', took 00:00:41 to complete
Deployed `redis-dev.yml' to `myfirstbosh'
```

We have successfully booted a VM and run the redis-server.

Well, we think so. How do we access the VM? AWS will allocate it a private IP address, as shown below, but you cannot access that IP from your development machine.

```
$ bosh vms
Deployment `redis-dev'

+-----------+---------+---------------+--------------+
| Job/index | State   | Resource Pool | IPs          |
+-----------+---------+---------------+--------------+
| redis/0   | running | common        | 10.62.73.100 |
+-----------+---------+---------------+--------------+

VMs total: 1
```

To access the redis-server from our local development machine, we need to allocate a public accessible IP to the VM. On AWS this is called an "Elastic IP". On BOSH this is called a "Static IP". Yep, funny joke I'm sure.

## Accessing redis remotely with Static IPs

BOSH can assign an AWS Elastic IP to a VM; though it cannot provision an Elastic IP.

To allocate an IP to job VMs:

1. Provision the Elastic IPs
1. Add them to the required job as a VIP network
1. Deploy the release again

Use fog to create an Elastic IP:

```
$ fog
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1' })
address = connection.addresses.create
address.public_ip
"107.22.225.123"
```

Next, we update our deployment manifest with the static IP `107.22.225.123`.

As we haven't modified the deployment manifest yet, since we generated it with `bosh-gen manifest`, we can re-generate the manifest and pass the IP:

```
$ cd ~/.bosh_deployments/redis-on-demand 
$ bosh-gen manifest redis-dev redis-on-demand c897319f-9b4b-41ae-9ed7-XXXXXXXX -a 107.22.225.123
    conflict  redis-dev.yml
Overwrite .../redis-dev.yml? (enter "h" for help) [Ynaqdh]
```

Press 'd' to see what will be changed (hence what you would add to do this manually):

```diff
  jobs:
  - name: redis
    template: redis
    instances: 1
    resource_pool: common
    networks:
    - name: default
      default:
      - dns
      - gateway
+   - name: vip_network
+     static_ips:
+     - 107.22.225.123
  properties: {}
```

To allocate IPs to job VMs, you add an extra "vip" network to the job. The generated deployment manifest already specifies a "vip" network, called "vip_network".

```yaml
networks:
- name: default
  type: dynamic
  cloud_properties:
    security_groups:
    - default
- name: vip_network
  type: vip
  cloud_properties:
    security_groups:
    - default
```

You can now re-deploy and it will show you what you are proposing to change:

```
$ bosh deploy
...
Jobs
redis
  changed networks: 
    + {"name"=>"vip_network", "static_ips"=>["107.22.225.123"]}
```

When deployment has completed your redis server is now accessible to your local development machine:

```
$ redis-cli -h 107.22.225.123
redis 107.22.225.123:6379> get inside
(nil)
redis 107.22.225.123:6379> set inside 123
OK
```

## Storing Redis DB on persistent attached disk

If a job VM needs to be replaced - for example if you scale it upwards or downwards - then the data will be lost. 

We need to use a persistent, attached disk with BOSH to ensure data is persistent whilst the VMs themselves are ephemeral. On AWS, we will be attaching a single EBS volume.

Before attaching an EBS volume:

```
$ bosh ssh redis 0
# df
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/xvda              1233648   1068624    102356  92% /
none                    834756       120    834636   1% /dev
none                    848504         0    848504   0% /dev/shm
none                    848504        52    848452   1% /var/run
none                    848504         0    848504   0% /var/lock
none                    848504         0    848504   0% /lib/init/rw
none                   1233648   1068624    102356  92% /var/lib/ureadahead/debugfs
/dev/xvdb2           152214948    207532 144275332   1% /var/vcap/data
/dev/loop0              126931      5646    119975   5% /tmp
```

To add an 8G EBS volume add the `persistent_disk: 8196` line to the redis job in `redis-dev.yml`:

```yaml
jobs:
- name: redis
  template: redis
  instances: 1
  persistent_disk: 8192
  resource_pool: common
  networks:
  - name: default
    default:
    - dns
    - gateway
  - name: vip_network
    static_ips:
    - 107.22.225.243
```

Re-deploy and confirm the persistent disk:

```
$ bosh deploy
...
Jobs
redis
  added persistent_disk: 8192
```

The available file structures after this deployment are:

```
$ df
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/xvda              1233648   1068648    102332  92% /
none                    834756       128    834628   1% /dev
none                    848504         0    848504   0% /dev/shm
none                    848504        52    848452   1% /var/run
none                    848504         0    848504   0% /var/lock
none                    848504         0    848504   0% /lib/init/rw
none                   1233648   1068648    102332  92% /var/lib/ureadahead/debugfs
/dev/xvdb2           152214948    207532 144275332   1% /var/vcap/data
/dev/loop0              126931      5646    119975   5% /tmp
/dev/xvdf1             8254272    149496   7685480   2% /var/vcap/store
```

Note that `/var/vcap/store` is now mounted as the EBS volume `/dev/xvdf1`.

The `bosh-gen job` generator already sets up a variable `$STORE` in the `templates/redis_ctl` file:

```bash
STORE=/var/vcap/store/redis
```

Additionally, the `redis.conf` is already telling redis to store data inside `/var/vcap/store` in preparation of this section.

Now that the EBS persistent disk is attached, let's store some data, upgrade the VM and check that our data is indeed persistent.

```
$ redis-cli -h 107.22.225.123
redis 107.22.225.123:6379> set inside 123
OK
redis 107.22.225.123:6379> get inside
"123"
```

In the deployment manifest, change the VM `instance_type` from `m1.small` to `m1.medium`:

```
resource_pools:
- name: common
  network: default
  size: 1
  persistent_disk: 8192
  stemcell:
    name: bosh-stemcell
    version: 0.6.2
  cloud_properties:
    instance_type: m1.medium
```

Now deploy the deployment and check that our data is retained:

```
$ bosh deploy
...
Resource pools
common
  cloud_properties
    changed instance_type: 
      - m1.small
      + m1.medium
...

$ redis-cli -h 107.22.225.123
redis 107.22.225.123:6379> get inside
"123"
```

## Configuring a Job from Deployment Manifest

Our redis server is now available on a standard port without any password protection on the public Internet. We can provide a password to `redis-server` via the configuration file. Though if we hardcode the password into `redis.conf` then we cannot change it between releases (dev, staging, QA, and production). 

Different configuration properties can be provided from the deployment manifest via the `properties: {}` key.

First, we will modify the deployment manifest to provide a specific port and password. Then we will modify the `redis.conf.erb` to use those values.

Replace `properties: {}` in the `redis-dev.yml` deployment manifest with the following:

```
properties:
  redis:
    port: 6379
    password: r3D!$
```

There are two redis configuration options we will add that will use properties from the deployment manifest.

These values are available within the job templates that end with `.erb` suffix. The `port` field value above can be placed in any such template using the snippet `<%= properties.redis.port %>`.

Add the following lines to `jobs/redis/templates/redis.conf.erb`:

```
port <%= properties.redis.port %>
requirepass <%= properties.redis.password %>
```

As before, modifying a job or package means that we must re-release and deploy.

```
$ bosh create release
$ bosh upload release
```

Then update `redis-dev.yml` to the new release number, then deploy.

```
$ bosh deploy
```