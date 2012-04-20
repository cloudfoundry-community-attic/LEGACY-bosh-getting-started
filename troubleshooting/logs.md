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
$ mkdir -p /tmp/bosh/logs/job/mysql.0
$ cd /tmp/bosh/logs/job/mysql.0
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

## Task logs

Each time you use the bosh CLI, it stores all the activities in a task log.

You can see the recent tasks performed by everyone and then display one of them:

```
$ bosh tasks recent 5
+----+-------+-------------------------+-----------------------------------------------+--------------------------------------+
| #  | State | Timestamp               | Description                                   | Result                               |
+----+-------+-------------------------+-----------------------------------------------+--------------------------------------+
| 47 | done  | 2012-04-20 19:23:59 UTC | ssh: cleanup:{"job"=>"mysql", "indexes"=>[0]} | #<File:0x00000002eb1cc8>             |
| 46 | done  | 2012-04-20 19:23:09 UTC | ssh: setup:{"job"=>"mysql", "indexes"=>[0]}   | #<File:0x00000004326618>             |
| 45 | done  | 2012-04-20 19:15:34 UTC | fetch logs                                    | 22cb3f46-b818-4c44-8f71-c1afdxxxxxxx |
| 44 | done  | 2012-04-20 19:12:57 UTC | retrieve vm-stats                             |                                      |
| 43 | done  | 2012-04-20 19:09:37 UTC | fetch logs                                    | fc339e17-544a-419f-9b69-927479xxxxxx |
+----+-------+-------------------------+-----------------------------------------------+--------------------------------------+

$ bosh task 47
```

## Job Agent logs

The instance that a Job runs on is controlled by the BOSH Director via an Agent. For all the communication that goes on between the Director and an Agent is stored in the Agent's logs.

```
$ mkdir -p /tmp/bosh/logs/agent/mysql.0
$ cd /tmp/bosh/logs/agent/mysql.0
$ bosh logs mysql 0 --agent
Tracking task output for task#48...

Fetching logs for mysql/0
  finding and packing log files (00:00:01)                                                          
Done                    1/1 00:00:01                                                                

Task 48: state is 'done', took 00:00:01 to complete

Downloading log bundle (99d07cbc-4fc9-4607-8f2b-08d412b760b3)...
Logs saved in `/tmp/bosh/logs/agent/mysql.0/mysql.0.2012-04-20@22-39-47.tgz'
$ tar xfv mysql.0.2012-04-20@22-39-47.tgz
./
./current
./lock
$ tail -n 200 current
```