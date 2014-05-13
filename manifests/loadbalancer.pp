class role_analytics::loadbalancer(
  $cluster_name,
  $rabbitmqport = '15672',
){
  class { 'haproxy': }

  haproxy::listen { "analytics-${cluster_name}" :
    ipaddress => $::ipaddress,
    ports     => $rabbitmqport,
  }

}
