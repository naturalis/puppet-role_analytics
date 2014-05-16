class role_analytics::redis (
  $cluster_name,
  $redis_password,
) {

  class { '::redis':
    bind        => $::ipaddress,
    manage_repo => true,
    ppa_repo    => 'ppa:rwky/redis',
    requirepass => $redis_password,
  }

  @@file_fragment { "logstash-input-${::fqdn}":
    order          => 100,
    content       => template('role_analytics/logstash_redis_input.erb'),
    tag           => "LS_CONFIG_INDEXER${cluster_name}",
  }

  $test_q = query_nodes('Class[Role_analytics::Elasticsearch_cluster]{cluster_name="test-cluster-003"}',hostname)
  $test_w = query_facts('Class[Role_analytics::Elasticsearch_cluster]',['ipaddress'])

  notify { $test_q :
  #  message => $test_q,
  }
  #$test_x = parsejson($test_w)
  #notify { $test_x : }


}
