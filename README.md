Puppet module for deployment of HEAT on OpenStack
=================================================

This module will deploy the HEAT api and tools, and map them
into an OpenStack environment.

It uses the model described here:
http://docs.openstack.org/developer/heat/getting_started/on_ubuntu.html

If deployed against Cisco COSI, you may need to make some modifications:
the installation above expects the "Services" tenant to be called "service" rather than "services"
the installation can use the default 'openrc' file, but expects two additional env variables to be defined:
SERVICE_HOST
SERVICE_PASSWORD

cat >> /root/openrc <<EOF
 
  export SERVICE_HOST=`facter ipaddress`
  export SERVICE_PASSWORD=Cisco123
EOF
With this it is still necessary to modify:
for i in heat-api.conf heat-api-cfn.conf heat-api-cloudwatch.conf heat-engine.conf; do sed -e 's/verybadpass/Cisco123/' -i /etc/heat/$i; sed -e 's/password=guest/password=openstack_rabbit_password/' -i /etc/heat/$i; sed -e '/openstack_rabbit_password/a rabbit_user=openstack_rabbit_user' -i /etc/heat/$i ; sed -e 's/service/services/' -i /etc/heat/$i; done

Also, it was necessary to create a "heat.conf" file. The contents below worked (replace the IP address with your controller/rabbit node):

cat > /etc/heat/heat.conf <<EOF
[DEFAULT]
rabbit_host=192.168.25.10
rabbit_port=5672
rabbit_hosts=$rabbit_host:$rabbit_port
rabbit_use_ssl=false
rabbit_userid=openstack_rabbit_user
rabbit_password=openstack_rabbit_password
rabbit_virtual_host=/
rabbit_retry_interval=1
rabbit_retry_backoff=2
[paste_deploy]
[rpc_notifier2]
[ec2authtoken]
[matchmaker_redis]
[matchmaker_ring]
EOF

