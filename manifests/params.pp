class heat::params {

  if($::osfamily == 'Redhat') {
    $package_name = 'heat'
    $service_name = 'heat-server'
  }
  elsif($::osfamily == 'Debian') {
    $package_name = 'heat'
    $service_name = 'heat-server'
  }
  else {

    fail("Unsupported osfamily ${$::osfamily}")

  }

}
