Puppet module for deployment of HEAT on OpenStack
=================================================

This module will deploy the HEAT api and tools, and map them
into an OpenStack environment deployed with Cisco's OpenStack Installation.

It uses the model described here:
http://docs.openstack.org/developer/heat/getting_started/on_ubuntu.html

The current code pulls from the git heat repository, and does not use packages (as they don't exist for Grizzly). 
In the future, the enovance heat model is a better approach, and will leverage the packages at least in the
Havana time frame.

The original code assumes the Service tenant is called 'service' while COSI uses 'services', you
 may want to remove the fixes in the init.pp for that change if you are not using the Cisco Install process
