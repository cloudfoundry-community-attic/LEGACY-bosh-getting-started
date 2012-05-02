# How to recreate microbosh config

If you move to a new machine, if `~/.microbosh` is accidentally deleted, or if you need to update any BOSH configuration (change your AWS credentials) then this is the troubleshooting guide for you.

## Recreate .microbosh

```
mkdir -p ~/.microbosh
chmod 700 ~/.microbosh
cd ~/.microbosh

git clone git://github.com/drnic/bosh-getting-started.git
cp -r bosh-getting-started/examples/microbosh/* .
vim config.yml
```

Next:

* replace all `PUBLIC_DNS_NAME` with your fog-created VM's `server.dns_name` (e.g. ec2-10-2-3-4.compute-1.amazonaws.com)
* replace `ACCESS_KEY_ID` with your AWS access key id
* replace `SECRET_ACCESS_KEY` with your AWS secret access key

## What is my BOSH URL (PUBLIC_DNS_NAME)?

You can get your BOSH URL from the bosh CLI:

```
$ bosh target
Current target is 'myfirstbosh (http://ec2-10-2-3-4.compute-1.amazonaws.com:25555) Ver: 0.5 (5384e09f)'
```

The host `ec2-10-2-3-4.compute-1.amazonaws.com` is the value of `PUBLIC_DNS_NAME`.

Alternately, you can look in your list of servers and try each different server as a BOSH director. Yay!!

```
$ fog
connection = Fog::Compute.new({ :provider => 'AWS', :region => 'us-east-1'})
connection.servers.map(&:dns_name)
["ec2-10-2-3-4.compute-1.amazonaws.com",  "ec2-X.X.X.X.compute-1.amazonaws.com", ..., ...]
exit
$ bosh target ec2-X.X.X.X.compute-1.amazonaws.com:25555
Error 103: cannot access director
$ bosh target ec2-10-2-3-4.compute-1.amazonaws.com:25555
Target set to 'http://ec2-10-2-3-4.compute-1.amazonaws.com:25555'
```

Hurray, you found it!

**NOTE:** Remember that BOSH Director runs (by default) on port 25555, not port 80. You need to include the target port :25555 in the URI above.

Now you can update `PUBLIC_DNS_NAME` in your fresh `config.yml` file.
 