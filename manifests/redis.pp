class role_analytics::redis (
  $cluster_name,
  $redis_password,
) {

  class { '::redis':
    bind        => $::ipaddress,
    manage_repo => true,
    ppa_repo    => 'ppa:rwky/redis',
  }

}
