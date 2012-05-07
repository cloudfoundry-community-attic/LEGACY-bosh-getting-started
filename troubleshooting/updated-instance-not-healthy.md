# Updated Instance Not Healthy?

When creating new jobs, you might get errors during deployment at the "Updating job NAME" step:

```
Updating job redis
  redis/0 (canary) (00:00:33)                                                                       
Error                   1/1 00:00:33                                                                

The task has returned an error status, do you want to see debug log? [Yn]: 
```

When you look at the debug log for the deploy task you may see:

```
E, [2012-05-07T21:04:14.532685 #30864] [task:69] ERROR -- : updated instance not healthy - /var/vcap/deploy/bosh/director/current/director/lib/director/instance_updater.rb:104:in `update'
/var/vcap/deploy/bosh/director/current/director/lib/director/job_updater.rb:58:in `block (5 levels) in update'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_common-0.4.0/lib/common/thread_formatter.rb:46:in `with_thread_name'
/var/vcap/deploy/bosh/director/current/director/lib/director/job_updater.rb:55:in `block (4 levels) in update'
/var/vcap/deploy/bosh/director/current/director/lib/director/event_log.rb:56:in `track'
/var/vcap/deploy/bosh/director/current/director/lib/director/job_updater.rb:54:in `block (3 levels) in update'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_common-0.4.0/lib/common/thread_pool.rb:83:in `call'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_common-0.4.0/lib/common/thread_pool.rb:83:in `block (2 levels) in create_thread'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_common-0.4.0/lib/common/thread_pool.rb:67:in `loop'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_common-0.4.0/lib/common/thread_pool.rb:67:in `block in create_thread'
```

The job VM still exists, but is in an error state:

```
$ bosh vms
Deployment `redis-dev'

+-----------+---------+---------------+--------------+
| Job/index | State   | Resource Pool | IPs          |
+-----------+---------+---------------+--------------+
| redis/0   | failing | common        | 10.62.73.100 |
+-----------+---------+---------------+--------------+

VMs total: 1
```

You will need to [SSH](../ssh.md) onto the failing Job VM to investigate.

NOTE: with current BOSH, on AWS, you need to be already inside AWS to SSH.

The following example instructions will upload the deployment manifest to an AWS VM (the BOSH director VM in this case), setup BOSH CLI, and use BOSH CLI to ssh into the failing VM:

```
$ cd ~/.bosh_deployments/redis-on-demand
$ scp redis-dev.yml ubuntu@ec2-10-2-3-4.compute-1.amazonaws.com:/tmp/redis-dev.yml
$ ssh ubuntu@ec2-10-2-3-4.compute-1.amazonaws.com

~$ sudo su -
# bosh deployment /tmp/redis-dev.yml 
Deployment set to '/tmp/redis-dev.yml'
# bosh ssh redis 0
Enter password (use it to sudo on remote host):
```

At this point, type in any random characters that you can remember. This will be the password you will use to run `sudo` on the remote VM whilst you are temporarily in your SSH session.

## Check job logs

In the redis tutorial, all log files were sent to `/var/vcap/sys/log/redis`.

```
$ cat /var/vcap/sys/log/redis/redis.std*
[1040] 07 May 21:03:44 # Fatal error, can't open config file '/var/vcap/jobs/redis/config/redis.yml'
[1046] 07 May 21:04:24 # Fatal error, can't open config file '/var/vcap/jobs/redis/config/redis.yml'
[1059] 07 May 21:05:04 # Fatal error, can't open config file '/var/vcap/jobs/redis/config/redis.yml'
```

Apparently we are expecting a `redis.yml` file. What is in that folder?

```$ ls /var/vcap/jobs/redis/config/
redis.conf
```

There is a config file there, just not `redis.yml`. What was trying to use `redis.yml` instead of `redis.conf`?

```$ cat /var/vcap/jobs/redis/bin/redis_ctl | grep redis.yml
    exec /var/vcap/packages/redis/bin/redis-server /var/vcap/jobs/redis/config/redis.yml ...
```

In this case, the redis_ctl has a bug. 

The resolution is to: 

1. fix "redis.yml" to "redis.conf"
1. create a new release
1. upload the new release
1. update the deployment manifest to the new release version
1. deploy again
