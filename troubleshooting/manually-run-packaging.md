# Manually run packaging

If the pre-compilation process of a package fails, or the output seems buggy in someway, you may want to manually re-run the compilation process, fix the packaging, re-run the compilation process, and repeat until you have it working. Each iteration will require re-uploading your release (slow) and re-deploying, which will provision clean VMs for compilation (slow).

An alternate way is to use Vagrant.

## Install and use Vagrant

Google it.

```
$ vagrant init lucid64
$ vagrant up
$ vagrant ssh
```

## Manually running packaging

An example sequence within the Vagrant VM:

```
# sudo su -
# cd /vagrant
# ls -al blobs/libyaml/*
yaml-0.1.4.tar.gz -> /Users/drnic/Projects/bosh_releases/eyredis-release/.blobs/e0e5e09192ab10a607e3da2970db492118f560f2
```

NOTE: The symlink is wired to the external development machine. We need to recreate the blob with its original file name.

```
# cd packages/libyaml
# mkdir -p libyaml
# cp ../../.blobs/e0e5e09192ab10a607e3da2970db492118f560f2 libyaml/yaml-0.1.4.tar.gz
```

Next, prepare the `/var/vcap/packages/...` folder structure; and run the packaging command:

```
# mkdir -p /var/vcap/packages/libyaml
# BOSH_INSTALL_TARGET=/var/vcap/packages/libyaml . packaging
```

In the `libyaml` example, there should be library files created:

```
# ls  /var/vcap/packages/libyaml/*
/var/vcap/packages/libyaml/include:
yaml.h

/var/vcap/packages/libyaml/lib:
libyaml-0.so.2  libyaml-0.so.2.0.2  libyaml.a  libyaml.la  libyaml.so  pkgconfig
```

## Before deploying

Within the Vagrant VM you have now polluted your original BOSH release project. You will need to remove the `packages/libyaml/libyaml*` files.
