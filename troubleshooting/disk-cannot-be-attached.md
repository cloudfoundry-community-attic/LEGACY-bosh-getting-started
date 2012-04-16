# Troubleshooting - disk cannot be attached

This is a collection of quirks I experienced and how I got around them. Or didn't.

## Changing instance type - random incorrect AZ choosen

Currently, if you change/upgrade a VM - it will drop your current VM and replace it with a new one and reattach the disk volume. 

On AWS, it is required that the VM be in the same AZ. Currently, this failure leaves you with a BOSH data inconsistency - you have an instance/VM, but no disk attached. BOSH is currently unhappy about this.

```
$ bosh deploy
Getting deployment properties from director...
Compiling deployment manifest...
Detecting changes in deployment...

Release
No changes

Compilation
No changes

Update
No changes

Resource pools
mysql
  cloud_properties
    changed instance_type: 
      - m1.xlarge
      + m1.medium

Networks
No changes

Jobs
mysql
  cloud_properties
    changed instance_type: 
      - m1.xlarge
      + m1.medium

Properties
No changes

Cloud
No changes

Please review all changes carefully
Deploying `wordpress-aws.yml' to `yourboshname' (type 'yes' to continue): yes
Tracking task output for task#52...

Preparing deployment
  binding deployment (00:00:00)                                                                     
  binding release (00:00:00)                                                                        
  binding existing deployment (00:00:01)                                                            
  binding resource pools (00:00:00)                                                                 
  binding stemcells (00:00:00)                                                                      
  binding templates (00:00:00)                                                                      
  binding unallocated VMs (00:00:00)                                                                
  binding instance networks (00:00:00)                                                              
Done                    7/7 00:00:01                                                                

Preparing DNS
  binding DNS (00:00:00)                                                                            
Done                    1/1 00:00:00                                                                

Preparing configuration
  binding configuration (00:00:00)                                                                  
Done                    1/1 00:00:00                                                                

Updating job mysql
  mysql/0 (canary) (00:04:27)                                                                       
Error                   1/1 00:04:27                                                                

The task has returned an error status, do you want to see debug log? [Yn]:
```

The debug log error was:

```
<Response><Errors><Error><Code>InvalidVolume.ZoneMismatch</Code><Message>The volume 'vol-f22e8e9d' is not in the same availability zone as instance 'i-04bb2563'</Message></Error></Errors><RequestID>d09c36df-75a6-47c5-8359-b2b42e1e2299</RequestID></Response> - /var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/aws-sdk-1.3.8/lib/aws/core/client.rb:277:in `return_or_raise'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/aws-sdk-1.3.8/lib/aws/core/client.rb:337:in `client_request'
(eval):3:in `attach_volume'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/aws-sdk-1.3.8/lib/aws/ec2/volume.rb:116:in `attach_to'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_aws_cpi-0.3.1/lib/cloud/aws/cloud.rb:445:in `block in attach_ebs_volume'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_aws_cpi-0.3.1/lib/cloud/aws/cloud.rb:437:in `upto'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_aws_cpi-0.3.1/lib/cloud/aws/cloud.rb:437:in `each'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_aws_cpi-0.3.1/lib/cloud/aws/cloud.rb:437:in `attach_ebs_volume'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_aws_cpi-0.3.1/lib/cloud/aws/cloud.rb:241:in `block in attach_disk'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_common-0.4.0/lib/common/thread_formatter.rb:46:in `with_thread_name'
/var/vcap/deploy/bosh/director/shared/gems/ruby/1.9.1/gems/bosh_aws_cpi-0.3.1/lib/cloud/aws/cloud.rb:237:in `attach_disk'
/var/vcap/deploy/bosh/director/current/director/lib/director/instance_updater.rb:150:in `attach_disk'
/var/vcap/deploy/bosh/director/current/director/lib/director/instance_updater.rb:241:in `update_resource_pool'
/var/vcap/deploy/bosh/director/current/director/lib/director/instance_updater.rb:59:in `block in update'
/var/vcap/deploy/bosh/director/current/director/lib/director/instance_updater.rb:33:in `step'
/var/vcap/deploy/bosh/director/current/director/lib/director/instance_updater.rb:59:in `update'
```

My only solution is to deleted the deployment. Sad panda.

I've raised this issue on the bosh-dev mailing list.


## Delete deployment before deleting release

I tried to delete the release. This was wrong. You delete the deployment.

## Failure to delete a deployment with missing disk

The data inconsistency meant that I also couldn't delete the mysql instance:

```
$ bosh delete deployment wordpress

You are going to delete deployment `wordpress'.

THIS IS A VERY DESTRUCTIVE OPERATION AND IT CANNOT BE UNDONE!

Are you sure? (type 'yes' to continue): yes
Tracking task output for task#54...

Deleting instances
  mysql/0: #<Bosh::Agent::FatalError: Unknown persistent disk: vol-f22e8e9d>: ["/var/vcap/bosh/agent/lib/agent/platform/ubuntu/disk.rb:52:in `lookup_disk_by_cid'", "/var/vcap/bosh/agent/lib/agent/platform/ubuntu.rb:27:in `lookup_disk_by_cid'", "/var/vcap/bosh/agent/lib/agent/message/disk.rb:198:in `unmount'", "/var/vcap/bosh/agent/lib/agent/message/disk.rb:193:in `process'", "/var/vcap/bosh/agent/lib/agent/handler.rb:250:in `process'", "/var/vcap/bosh/agent/lib/agent/handler.rb:235:in `process_long_running'", "/var/vcap/bosh/agent/lib/agent/handler.rb:173:in `block (2 levels) in handle_message'", "<internal:prelude>:10:in `synchronize'", "/var/vcap/bosh/agent/lib/agent/handler.rb:171:in `block in handle_message'"] (00:00:01)
  wordpress/0 (00:00:38)                                                                            
  wordpress/1 (00:00:41)                                                                            
  nginx/0 (00:00:41)                                                                                
Error                   4/4 00:00:41                                                                
```

The solution is to use the `--force` flag:

```
$ bosh delete deployment wordpress --force

You are going to delete deployment `wordpress'.

THIS IS A VERY DESTRUCTIVE OPERATION AND IT CANNOT BE UNDONE!

Are you sure? (type 'yes' to continue): yes
Tracking task output for task#56...

Deleting instances
  mysql/0 (00:00:33)                                                                                
Done                    1/1 00:00:33                                                                

Removing deployment artifacts
  detach stemcells (00:00:00)                                                                       
  detaching release versions (00:00:00)                                                             
Done                    3/3 00:00:00                                                                

Deleting properties
  destroy deployment (00:00:00)                                                                     
Done                    0/0 00:00:00                                                                

Task 56: state is 'done', took 00:00:33 to complete
Deleted deployment 'wordpress'
```
