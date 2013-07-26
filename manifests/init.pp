class heat {

  package { ["gcc","python2.7-dev","git","build-essential","devscripts","debhelper","python-all","gdebi-core","python-setuptools","python-prettytable","python-lxml","libguestfs*"]:
    ensure => latest,
  } 
  exec {"pip-install-python-heatclient":
    path    => ["/bin","/usr/bin","/sbin","/usr/sbin","/usr/local/bin"],
    command => 'pip install python-heatclient',
    unless  => 'which heat',
  }
}
