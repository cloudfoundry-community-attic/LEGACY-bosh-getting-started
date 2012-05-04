# Database cleaning

If all fails, if BOSH cannot clean up a data structure that does not map to reality (it may think that a VM exists that in fact doesn't) then you can finally resort to connecting to the BOSH PostgreSQL database and fixing the data directly.

By default, BOSH PostgreSQL server has a single user account `bosh` with a password `b0$H`. Hopefully your security group/firewall precludes external access to your PostgreSQL server because I just told everyone what your credentials are.

To access your BOSH PostgreSQL server, first SSH into your BOSH director instance, and then connect via the `psql` command line tool:

```
local$ ssh ubuntu@ec2-10-2-3-4.compute-1.amazonaws.com
ubuntu$ psql -h localhost -U bosh -W
```

## Schema

To get you started, below is the list of tables in the BOSH database at the time of writing.

```
ubuntu$ psql -h localhost -U bosh -W
bosh=# SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

 schema_migrations
 compiled_packages
 releases
 users
 packages
 release_versions
 packages_release_versions
 tasks
 instances
 vms
 release_versions_templates
 deployments
 deployments_stemcells
 stemcells
 deployment_properties
 deployments_release_versions
 log_bundles
 templates
 persistent_disks
 vsphere_cpi_schema
 deployment_problems
 vsphere_disk
 aws_registry_schema
 aws_instances
(24 rows)
```
