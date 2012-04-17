# Details of the Deployment Manifest

In this document, let's look at the parts of a deployment manifest file for AWS.

There are 10 top-level properties of a deployment manifest (such as [examples/wordpress/deployment-manifest-initial.yml](../../examples/wordpress/deployment-manifest-initial.yml))

* name - expected deployment name
* director_uuid - confirmation of target BOSH director
* release - specific release version (specific uploaded combination of stemcell & packages)
* compilation - instances to be used for compiling new release packages
* update - how deployment changes are handled
* networks - 
* resource_pools
* jobs
* properties
* cloud
