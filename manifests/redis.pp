class role_analytics::redis (
  $cluster_name   = undef,
  $redis_password = undef,
) {

  class { '::redis':
    bind          => $::ipaddress,
    manage_repo   => true,
    ppa_repo      => 'ppa:rwky/redis',
    requirepass   => $redis_password,
  }

  @@file_fragment { "logstash-input-${::fqdn}":
    order         => 100,
    content       => template('role_analytics/logstash_redis_input.erb'),
    tag           => "LS_CONFIG_INDEXER_${cluster_name}",
  }

  file { '/etc/sysctl.conf':
    ensure        => present,
    }
  file_line { 'Add vm overcommit_memory to /etc/sysctl.conf':
    path          => '/etc/sysctl.conf',
    line          => 'vm.overcommit_memory=1',
  }
}
