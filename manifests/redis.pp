class role_analytics::redis (
  $cluster_name,
  $redis_password,
) {

  class { '::redis':
    bind        => $::ipaddress,
  }

}
