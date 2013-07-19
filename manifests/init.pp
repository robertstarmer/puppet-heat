class heat {
  package {["python-heat","heat-engine","heat-common","heat-api","heat-api-cfn","heat-api-cloudwatch"]:
    ensure => present,
  }
  
}
