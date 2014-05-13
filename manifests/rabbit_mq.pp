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
  } ->

  rabbitmq_exchange { 'logstash-exchange@':
  user     => 'logstash',
  password => $,
  type     => 'direct',
  ensure   => present,
}

  #file_fragment { 'begin output':
  #    tag     => "LS_CONFIG_${cluster_name}",
  #    content => "output { elasticsearch { cluster => '${cluster_name}' } }",
  #    order   => 699,
  #}

  @@file_fragment { "logstash-input-${::fqdn}":
    order          => 100,
    content       => template('role_analytics/logstash_rabbit_input.erb'),
    tag           => "LS_CONFIG_${cluster_name}",
  }

   @@haproxy::balancermember { $fqdn:
    listening_service => "analytics-${cluster_name}",
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress,
    ports             => '5672',
  }




}
