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
  }

  rabbitmq_user_permissions { 'logstash':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

  rabbitmq_exchange { 'logstash-exchange':
    user     => 'logstash',
    password => $rabbit_logstash_password,
    type     => 'direct',
    ensure   => present,
  }
}