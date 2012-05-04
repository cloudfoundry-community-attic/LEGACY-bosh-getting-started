# Create a new release

You can quickly create the initial scaffold for a new release using the 3rd-party `bosh-gen` tool (ok, to be fair, Dr Nic wrote it).

Install the tool using RubyGems:

```
gem install bosh-gen
```

```
~/.bosh_deployments/redis-on-demand
bosh-gen new redis-on-demand
cd redis-on-demand
```

This will generate the scaffold for the release in a folder `~/.bosh_deployments/redis-on-demand/redis-on-demand`. Later we will put the one or more deployment manifest files in the parent folder `~/.bosh_deployments/redis-on-demand`.

The generated project will also be converted into a Git repository. If you don't want this, then delete the `~/.bosh_deployments/redis-on-demand/redis-on-demand/.git` folder .

## Installing the redis server

```
$ bosh-gen package redis
      create  packages/redis/packaging
      create  packages/redis/pre_packaging
      create  packages/redis/spec
```

The initial `spec` manifest shows below that this package requires no files and has no dependencies on any other packages.

```yaml
$ cat packages/redis/spec
---
name: redis
dependencies: []
files: []
```

If we were to attempt to create a release now, we'll see that BOSH requires that packages all require one or more source files.

```
$ bosh create release
Syncing blobs...

Building DEV release
---------------------------------

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
Release manifest: .../dev_releases/tmp-1.yml
```



## Starting processes or jobs

```
$ bosh generate job myserver
create	jobs/myserver
create	jobs/myserver/templates
create	jobs/myserver/spec
create	jobs/myserver/monit

Generated skeleton for `myserver' job in `jobs/myserver'
```