# Create a new release

You can quickly create the initial scaffold for a new release using the bosh CLI:

```
bosh init release mysystem
cd mysystem
git init; git add .; git commit -m "Initial commit"
```

## Installing software or packages

```
$ bosh generate package myserver
create	packages/myserver
create	packages/myserver/packaging
create	packages/myserver/pre_packaging
create	packages/myserver/spec

Generated skeleton for `myserver' package in `packages/myserver'
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