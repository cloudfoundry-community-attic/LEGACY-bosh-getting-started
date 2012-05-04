# Database cleaning

If all fails, if BOSH cannot clean up a data structure that does not map to reality (it may think that a VM exists that in fact doesn't) then you can finally resort to connecting to the BOSH PostgreSQL database and fixing the data directly.

By default, BOSH PostgreSQL server has a single user account `bosh` with a password `b0$H`. Hopefully your security group/firewall precludes external access to your PostgreSQL server because I just told everyone what your credentials are.

To access your BOSH PostgreSQL server, first SSH into your BOSH director instance, and then connect via the `psql` command line tool:

```
$ ssh ubuntu@ec2-10-2-3-4.compute-1.amazonaws.com
# psql -h localhost -U bosh -W
```

