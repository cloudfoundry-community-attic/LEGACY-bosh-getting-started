# Modifying your BOSH

BOSH is open source and a relatively young piece of software. You may quickly want to help and contribute to the project. There are a couple of steps to follow to update your BOSH installation with any local changes. 

There are also a few steps to have your changes merged upstream for everyone to enjoy, though that is a different post.

## Fetch the source code

Follow the section "[OSS Contributions](https://github.com/cloudfoundry/bosh#readme)" in the BOSH source code for how to use Gerrit to clone and contribute to the source code.

The short summary is

Create an account at [http://reviews.cloudfoundry.org/](http://reviews.cloudfoundry.org/ "Gerrit Code Review"). Then clone the bosh git repository from gerrit (rather than from github).

```
gem install gerrit-cli
gerrit clone ssh://reviews.cloudfoundry.org:29418/bosh
cd bosh
```

You're now ready to contribute any changes back to CloudFoundry.

## Deploying your modified BOSH code

When you [initially created your BOSH](../creating-a-bosh-from-scratch.md), you used a `chef_deployer` script from your local machine.

The command you ran was effectively, from within your BOSH source code:

```
cd release
ruby ../chef_deployer/bin/chef_deployer deploy ~/.microbosh
```

It used `~/.microbosh/config.yml` to determine the location of the instances to install the various components/jobs of the BOSH. We installed all jobs into the one instance.

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

