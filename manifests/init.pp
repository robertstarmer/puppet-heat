class heat {

  Exec { logoutput=>true }
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
    command => "bash \$(for i in /etc/heat/heat*.conf ; do sed -e \"s/verybadpass/${::admin_password}/\" -i \$i; sed -e \"s/password=guest/password=${::rabbit_password}/\" -i \$i; sed -e \"/openstack_rabbit_password/a rabbit_user=${::rabit_user}\" -i \$i; sed -e \"s/service[ ]*$/services/\" -i \$i; done)",
    unless => 'grep Cisco123 /etc/heat/heat-api.conf',
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
}
