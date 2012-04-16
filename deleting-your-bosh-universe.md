# Clean up! Deleting your BOSH universe

You've created a BOSH, you played with it and deployed environments. How do you clean up? (That is, how do you stop paying AWS for all your tutorial VM?!)

```
$ bosh delete deployment wordpress

You are going to delete deployment `wordpress'.

THIS IS A VERY DESTRUCTIVE OPERATION AND IT CANNOT BE UNDONE!

Are you sure? (type 'yes' to continue): yes
Tracking task output for task#44...

Deleting instances
mysql/0, nginx/0, wordpress/0,...   |                        | 0/4 00:00:09  ETA: --:--:--
```

After cleaning up your BOSH created VMs, lastly you delete your BOSH VM:

```
$ fog
  Welcome to fog interactive!
  :default provides AWS and VirtualBox
connection = Fog::Compute.new({:provider => 'AWS'})
connection.servers.last.destroy
connection.addresses.last.destroy
connection.images.all(:name => 'BOSH*').each {|i| i.deregister true}
```

TODO - make this more advanced. Perhaps setup VMs with tags etc.