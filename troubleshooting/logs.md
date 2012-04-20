# Logs

There are lots of logs in BOSH. Director tasks are all logged. Agents running on controlled instances maintain their own logs. Each job - mapping to one or more processes on a single instance - has logs.

## Job logs

You access logs by knowing the job and index. 

Say there is a database error. You need your mysql logs. First, determine the job/index.

```
$ bosh vms
Deployment `wordpress'

+-------------+---------+---------------+-------------------------------+
| Job/index   | State   | Resource Pool | IPs                           |
+-------------+---------+---------------+-------------------------------+
| mysql/0     | running | common        | 10.190.215.248, 23.23.249.123 |
| nginx/0     | running | common        | 10.190.47.40, 23.23.247.237   |
| wordpress/0 | running | common        | 10.111.27.137, 23.23.249.121  |
+-------------+---------+---------------+-------------------------------+
```

Next, use `bosh logs` to get a tarball of that job's logs.

```
$ mkdir -p /tmp/bosh/logs/mysql
$ cd /tmp/bosh/logs/mysql
$ bosh logs mysql 0
Tracking task output for task#43...

Fetching logs for mysql/0
  finding and packing log files (00:00:01)                                                          
Done                    1/1 00:00:01                                                                

Task 43: state is 'done', took 00:00:01 to complete

Downloading log bundle (fc339e17-544a-419f-9b69-927479xxxxxx)...
Logs saved in `/private/tmp/bosh/logs/mysql/mysql.0.2012-04-20@12-09-38.tgz'
```

Unpack the tarball to access the logging goodness:

```
$ tar xfv mysql.0.2012-04-20@12-09-38.tgz
x ./
x ./mysql/
x ./mysql/mysqld.err.log
```

For the mysql job, there is only one log file `mysqld.err.log`. You can look at the last 200 lines with:

```
tail -n 200 mysql/mysqld.err.log
```


