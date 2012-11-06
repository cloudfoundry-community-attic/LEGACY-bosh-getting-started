# Debugging PowerDNS on MicroBOSH

After deploying a single VM release "logstash-micro", PowerDNS on the microbosh should have records for each of its networks. See below, there are entries for `0.micro.default.logstash-micro.bosh` and `0.micro.elastic.logstash-micro.bosh`.

```
$ ssh vcap@microbosh

$ /var/vcap/packages/postgres/bin/psql -p 5445 -d powerdns -U rick -W
(password: deckard)

powerdns=# select * from records;
 id |                name                 | type |                     content                      |  ttl  | prio | change_date | domain_id 
----+-------------------------------------+------+--------------------------------------------------+-------+------+-------------+-----------
  2 | bosh                                | NS   | ns.bosh                                          | 14400 |      |             |         1
  3 | ns.bosh                             | A    |                                                  | 14400 |      |             |         1
  1 | bosh                                | SOA  | localhost hostmaster@localhost 0 10800 604800 30 |   300 |      |             |         1
 12 | 0.micro.default.logstash-micro.bosh | A    | 10.190.101.145                                   |   300 |      |  1352237841 |         1
 13 | 101.190.10.in-addr.arpa             | SOA  | localhost hostmaster@localhost 0 10800 604800 30 | 14400 |      |             |         4
 14 | 101.190.10.in-addr.arpa             | NS   | ns.bosh                                          | 14400 |      |             |         4
 15 | 145.101.190.10.in-addr.arpa         | PTR  | 0.micro.default.logstash-micro.bosh              |   300 |      |  1352237841 |         4
 16 | 0.micro.elastic.logstash-micro.bosh | A    | 107.21.226.107                                   |   300 |      |  1352237841 |         1
 17 | 226.21.107.in-addr.arpa             | SOA  | localhost hostmaster@localhost 0 10800 604800 30 | 14400 |      |             |         5
 18 | 226.21.107.in-addr.arpa             | NS   | ns.bosh                                          | 14400 |      |             |         5
 19 | 107.226.21.107.in-addr.arpa         | PTR  | 0.micro.elastic.logstash-micro.bosh              |   300 |      |  1352237841 |         5
```