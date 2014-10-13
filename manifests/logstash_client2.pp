class role_analytics::logstash_client(

  $cluster_name                     = undef,
  $redis_password                   = undef,
  $version                          = '1.4',
  $logstash_input                   = '',
  $logstash_filter                  = '',
  $use_collectd                     = true,
  $collectd_disks                   = ['dm-2'],
  $use_dashboard                    = true,
  $dashboard_name                   = 'host-baseboard',
  $kibana_ip                        = '10.42.1.111',
  $redis_ip                         = ["10.42.1.118","10.42.1.116","10.42.1.117"],
  $host_specific                    = undef,
  $config_hash = {
    # 'LS_USER' => 'logstash',
    # 'LS_GROUP' => 'logstash',
     'HEAP_SIZE' => '200',
   }
){

  if ! defined(Class["role_analytics::logstash_indexer"]) {

    class { 'logstash':
      java_install => true,
      manage_repo  => true,
      repo_version => $version,
      init_defaults => $config_hash,
    }

    $redis_cluster_string = join($redis_ip,'","')

    if $use_collectd {

      class { '::collectd':
        purge                 => true,
        recurse               => true,
        purge_config          => true,
      }
      class { 'collectd::plugin::load': }
      class { 'collectd::plugin::memory': }
      class { 'collectd::plugin::disk':
        disks                 => $collectd_disks,
      }
      class { 'collectd::plugin::interface': }
      class { 'collectd::plugin::df': }
      class { 'collectd::plugin::uptime': }
      class { 'collectd::plugin::network':
        timetolive    => '70',
        maxpacketsize => '42',
        forward       => false,
        reportstats   => true,
        servers       => { '127.0.0.1' => {
          'port'          => '25826',
          },
        },
      }

      file_fragment { 'input collectd':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => '  collectd { tags => ["collectd"] }
        ',
        order                 => 100,
      }
    }

    service {'logstash':
      ensure                      => running,
      enable                      => true,
      require                     => Package['logstash'],
      hasrestart                  => true,
    }

    file_fragment { 'begin input':
      tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
      content               => 'input {
      ',
      order                 => 0,
      }

      file_fragment { 'input':
        tag                     => "LS_CONFIG_CLIENT_${cluster_name}",
        content                 => $logstash_input,
        order                   => 200,
      }

      file_fragment { 'end_input':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => '
      }
      ',
      order                 => 398,
    }

    file_fragment { 'begin filter':
      tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
      content               => 'filter {
      ',
      order                 => 399,
      }

      file_fragment { 'filter':
        tag                     => "LS_CONFIG_CLIENT_${cluster_name}",
        content                 => $logstash_filter,
        order                   => 500,
      }

      file_fragment { 'end filter':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => '
      }
      ',
      order                 => 698,
    }

    file_fragment { 'output':
      tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
      content               => template('role_analytics/logstash_redis_output.erb'),
      order                 => 699,
    }

    File_fragment <<| tag == "LS_CONFIG_CLIENT_${cluster_name}" |>> {
      before                  => File_concat['/etc/logstash/conf.d/logstash_client.conf']
    }

    file_concat { '/etc/logstash/conf.d/logstash_client.conf':
      tag                     => "LS_CONFIG_CLIENT_${cluster_name}",
      owner                   => 'logstash',
      group                   => 'logstash',
      mode                    => '0640',
      require                 => Package['logstash'],
      notify                  => Service['logstash'],
    }

    if $use_dashboard {
      file {"/tmp/${dashboard_name}.json":
        ensure                    => "present",
        mode                      => "644",
        content                   => template("role_analytics/${dashboard_name}.json.erb"),
        notify                    => Exec['install_dashboard'],
      }
      exec { 'install_dashboard':
        command                   => "/usr/bin/curl -XPUT http://${kibana_ip}:9200/kibana-int/dashboard/host-${hostname} -T /tmp/${dashboard_name}.json",
        refreshonly               => true,
      }

}
}
}