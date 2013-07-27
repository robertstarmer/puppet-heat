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
    unless  => "cinder --version |& grep 1.0.4",
    notify  => Exec['pip-upgrade-boto','pip-upgrade-paramiko'],
  }
  exec {"pip-upgrade-boto":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "pip install --upgrade boto",
    require  => Exec["pip-upgrade-cinderclient"],
  }
  exec {"heat-fix-passwd":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "for i in heat-api.conf heat-api-cfn.conf heat-api-cloudwatch.conf heat-engine.conf; do sed -e 's/ = verybadpass/=Cisco123/' -i /etc/heat/$i; sed -e 's/password=guest/password=openstack_rabbit_password' -i /etc/heat/$i; sed -e '/openstack_rabbit_password/a rabbit_user=openstack_rabbit_user' -i /etc/heat/$i; done",
    unless => 'grep Cisco123 /etc/heat/heat-api.conf',
  }
    
  exec {"pip-upgrade-paramiko":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => "pip install --upgrade paramiko",
    require  => Exec["pip-upgrade-cinderclient"],
  }

  exec {"heat-install":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin","/tmp/heat","/tmp/heat/bin"],
    command => "/tmp/heat/install.sh",
    unless => "which heat-api",
    require => [Vcsrepo['/tmp/heat'],Exec['pip-upgrade-boto','pip-upgrade-cinderclient']],
  }
}
