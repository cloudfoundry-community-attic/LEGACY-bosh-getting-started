# Modifying your BOSH

BOSH is open source and a relatively young piece of software. You may quickly want to help and contribute to the project. There are a couple of steps to follow to update your BOSH installation with any local changes. 

There are also a few steps to have your changes merged upstream for everyone to enjoy, though that is a different post.

## Fetch the source code

Create an account at [http://reviews.cloudfoundry.org/](http://reviews.cloudfoundry.org/ "Gerrit Code Review"). Then clone the bosh git repository from gerrit (rather than from github).

```
gem install gerrit-cli
gerrit clone ssh://reviews.cloudfoundry.org:29418/bosh
cd bosh
```

You're now ready to contribute any changes back to CloudFoundry.

## Modify BOSH source code

Create a branch, make changes, commit your changes into your branch.

```
git checkout -b my-new-changes
git commit
```

## Deploying your modified BOSH code

When you [initially created your BOSH](../creating-a-bosh-from-scratch.md), you used a `chef_deployer` script from your local machine.

The command you ran was effectively, from within your BOSH source code:

```
cd release
ruby ../chef_deployer/bin/chef_deployer deploy ~/.chefbosh
```

It used `~/.chefbosh/config.yml` to determine the location of the instances to install the various components/jobs of the BOSH. We installed all jobs into the one instance.

This `config.yml` did not determine which version of BOSH source code was to be installed on each BOSH instance (we only used one instance, but you could have used a cluster of instances).

When we created the BOSH, the BOSH source file [`release/config/repos.yml`](https://github.com/drnic/bosh/blob/master/release/config/repos.yml) determined which version of BOSH to use. At the time of writing it looks like:

```yaml
---
bosh:
  uri: git@github.com:cloudfoundry/bosh.git
  roles:
  - blobstore
  - director
  - health_monitor
```

The value `bosh.uri` tells the `chef_deployer` where to get the source from to deploy the BOSH source code on your BOSH instances.

To deploy our local changes to your BOSH instances, tell `chef_deployer` to use it the local folder instead of the `bosh.uri` value:

```
ruby ../chef_deployer/bin/chef_deployer deploy ~/.chefbosh --local
```

## Troubleshooting

When running the `chef_deployer` command above, with all the git commands, rsyncing and chef that goes on, its possible that something might not work.

Try deleting the local copy and the remote copy of BOSH:

```
$ rm -rf /tmp/repos/
$ ssh ubuntu@BOSH_DIRECTOR
sudo su -
rm -rf /var/vcap/deploy/repos/bosh/
```

Then re-run the `chef_deployer` command above.
