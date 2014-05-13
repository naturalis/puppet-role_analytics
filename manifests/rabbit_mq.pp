class role_analytics::rabbit_mq (
  $cluster_name,
  $rabbit_logstash_password,
) {


  class { '::rabbitmq':
    service_manage    => true,
    port              => '5672',
    delete_guest_user => true,
  }

  rabbitmq_user { 'logstash':
    admin    => true,
    password => $rabbit_logstash_password,
  } ->

  rabbitmq_user_permissions { 'logstash@/':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

  @@role_analytics::logstash_indexer::indexer_config { "logstash-input-${::fqdn}":
    type          => 'input',
    content       => template('role_analytics/logstash_rabbit_input.erb'),
    tag           => "${cluster_name}_indexer_config",
    cluster_name  => $cluster_name,
  }

   @@haproxy::balancermember { $fqdn:
    listening_service => "analytics-${cluster_name}",
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress,
    ports             => '15672',
    options           => 'check'
  }




}
