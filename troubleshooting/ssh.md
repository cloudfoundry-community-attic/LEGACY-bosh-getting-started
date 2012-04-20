# SSH into deployment instances

When you need to sticky beak around your deployment instances - the instances that are running your deployment jobs - you can use the `bosh ssh` command.

You reference which instance to SSH into via a job name and index. You can see the current list of instances and jobs with `bosh vms`

```
$ bosh vms wordpress
Deployment `wordpress'

+-------------+---------+---------------+------------------------------+
| Job/index   | State   | Resource Pool | IPs                          |
+-------------+---------+---------------+------------------------------+
| mysql/0     | running | common        | 10.64.43.243, 23.23.249.123  |
| nginx/0     | running | common        | 10.72.215.86, 23.23.247.237  |
| wordpress/0 | running | common        | 10.110.71.177, 23.23.249.121 |
+-------------+---------+---------------+------------------------------+
```

We could SSH into any instance using its `Job/index` information:

```
bosh ssh mysql 0
bosh ssh nginx 0
bosh ssh wordpress 0
```

**This will not work from your laptop.**

[You currently](http://groups.google.com/a/cloudfoundry.org/group/bosh-users/msg/514052ab1fb851e4) need to use the `bosh ssh` command from within the AWS universe as its implemented to use private IP addresses.

This takes a few lines to setup:

```
$ cd /tmp/microbosh/bosh-getting-started/examples/microbosh
$ scp wordpress-aws.yml ubuntu@BOSH_DIRECTOR:/tmp/wordpress-aws.yml
$ ssh ubuntu@BOSH_DIRECTOR
# sudo su -
# gem install bosh_cli
# bosh target localhost:25555
# bosh deployment /tmp/wordpress-aws.yml
```

You can now SSH into the deployment instances from within your BOSH instance:

```
# bosh ssh nginx 0
Enter password (use it to sudo on remote host): 
```

Enter a password here that you'll later use on the target instance when you use `sudo`.



