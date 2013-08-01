class heat {

  package { ["gcc","python2.7-dev","git","build-essential","devscripts","debhelper","python-all","gdebi-core","python-setuptools","python-prettytable","python-lxml","libguestfs*"]:
    ensure => latest,
  } 
  exec {"pip-install-python-heatclient":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => 'pip install python-heatclient',
    unless  => 'which heat',
  }
  vcsrepo {'/tmp/heat':
    ensure => present,
    provider => git,
    source => "https://github.com/openstack/heat",
  }
  exec {"pip-upgrade-cinderclient":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "pip install --upgrade python-cinderclient",
    unless  => 'grep 1.0.4 /usr/local/bin/cinder',
    notify  => Exec['pip-upgrade-boto','pip-upgrade-paramiko'],
  }
  exec {"pip-upgrade-boto":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "pip install --upgrade boto",
    refreshonly => true,
    require  => Exec["pip-upgrade-cinderclient"],
  }
  exec {"pip-upgrade-paramiko":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "pip install --upgrade paramiko",
    refreshonly => true,
    require  => Exec["pip-upgrade-cinderclient"],
  }

  exec {"heat-install":
    cwd => '/tmp/heat',
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin","/tmp/heat"],
    command => "/tmp/heat/install.sh",
    unless => "test -f /etc/heat/heat.conf.sample",
    require => Vcsrepo['/tmp/heat'],
  } 

  exec {"heat-fix-passwd":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "bash \$(for i in /etc/heat/heat*.conf ; do sed -e \"s/verybadpass/${::admin_password}/\" -i \$i; sed -e \"s/password=guest/password=${::rabbit_password}/\" -i \$i; sed -e \"/openstack_rabbit_password/a rabbit_user=${::rabbit_user}\" -i \$i; sed -e \"s/service[ ]*$/services/\" -i \$i; done)",
    unless => 'grep Cisco123 /etc/heat/heat-api.conf',
    require => Exec['heat-install']
  }
    
  exec {"heat-db-install":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    cwd     => '/tmp/heat/bin',
    command => "heat-db-setup deb -r ${::mysql_root_password}",
    unless  => "echo 'SELECT * FROM migrate_version;' | mysql -u heat --password=heat heat",
    require => Exec['heat-install']
  }

  file {"/etc/heat/heat.conf":
    ensure => present,
    content => "
[DEFAULT]
rabbit_host=${::controller_node_address}
rabbit_port=5672
rabbit_use_ssl=false
rabbit_userid=${::rabbit_user}
rabbit_password=${::rabbit_password}
rabbit_virtual_host=/
rabbit_retry_interval=1
rabbit_retry_backoff=2
[paste_deploy]
[rpc_notifier2]
[ec2authtoken]
[matchmaker_redis]
[matchmaker_ring]
",
    require => Exec['heat-install'],
  }

  exec {"heat-keystone":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    environment => ["SERVICE_ENDPOINT=http://${ipaddress}:35357/v2.0/","SERVICE_TOKEN=keystone_admin_token","SERVICE_PASSWORD=${::admin_password}","OS_AUTH_URL=http://${ipaddress}:5000/v2.0/","OS_USERNAME=admin OS_PASSWORD=Cisco123","SERVICE_HOST=${ipaddress}","SERVICE_TENANT=services","ADMIN_ROLE=admin","OS_TENANT=services"],
    command => "sed -e 's/service 1/services 1/' -i /usr/local/bin/heat-keystone-setup ; heat-keystone-setup",
    unless  => "keystone endpoint-list | grep 8004",
    require => Exec['heat-install'],
  }

#   glance_image { 'ubuntu1204':
#      ensure           => present,
#      name             => "Ubuntu 12.04 cloudimg amd64",
#      is_public        => yes,
#      container_format => ovf,
#      disk_format      => 'qcow2',
#      source           => 'http://uec-images.ubuntu.com/releases/precise/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img',
#      require => Exec["heat-keystone"],
#    }
#
#   glance_image { 'fedora17cfn':
#      ensure           => present,
#      name             => "Fedora 17 HEAT cfn amd64",
#      is_public        => yes,
#      container_format => ovf,
#      disk_format      => 'qcow2',
#      source           => 'http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F18-x86_64-cfntools.qcow2',
#      require => Exec["heat-keystone"],
#    }

   file {"/tmp/test_heat.sh":
     ensure => present,
     mode => 0777,
     content => '#!/bin/bash
source /root/openrc
wget -O F18-x86_64-cfntools.qcow2 http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F18-x86_64-cfntools.qcow2
wget -O WordPress_Single_Instance_deb.template https://raw.github.com/openstack/heat-templates/master/cfn/WordPress_Single_Instance_deb.template
sed -e \'s/Values" : "U10/Pattern" : "U10.*/\' -i WordPress_Single_Instance_deb.template
glance image-create --name=U10-x86_64-cfntools --disk-format=qcow2 --container-format=bare < F18-x86_64-cfntools.qcow2
key_path=/tmp/id_rsa
if [ ! -f $key_path ]; then
  ssh-keygen -f $key_path -t rsa -N \'\' 
fi
nova keypair-add --pub_key /tmp/id_rsa.pub ${USER}_key
quantum security-group-rule-create --protocol icmp --direction ingress default
quantum security-group-rule-create --protocol tcp --port-range-min 22 \
  --port-range-max 22 --direction ingress default
quantum security-group-rule-create --protocol tcp --port-range-min 80 \
  --port-range-max 80 --direction ingress default
quantum net-create net1
quantum subnet-create net1 10.0.0.0/24
heat stack-create wordpress -f=WordPress_Single_Instance_deb.template --parameters="InstanceType=m1.xlarge;DBUsername=${USER};DBPassword=verybadpassword;KeyName=${USER}_key;LinuxDistribution=U10"
sleep 15
heat stack-list
sleep 15
heat event-list wordpress
sleep 15
heat stack-show wordpress
',
    require => Exec['heat-install'],
  }
       

}
