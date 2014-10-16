class role_analytics::logstash_client2(

  $cluster_name               = undef,
  $redis_password             = undef,
  $version                    = '1.4',
  $logstash_input             = '',
  $logstash_filter            = '',
  $use_collectd               = true,
  $collectd_disks             = ['dm-2'],
  $use_dashboard              = true,
  $dashboard_name             = 'host-baseboard',
  $kibana_ip                  = '10.42.1.111',
  $redis_ip                   = ["10.42.1.118","10.42.1.116","10.42.1.117"],
  $host_specific              = undef,
  $config_hash                = { 'LS_HEAP_SIZE' => '200m', 'LS_USER' => 'root', }
){

  stage { 'pre':
  before => Stage["main"],
  }

  if ! defined(Class["role_analytics::logstash_indexer"]) {

    class { 'logstash':
      java_install            => true,
      manage_repo             => true,
      repo_version            => $version,
      init_defaults           => $config_hash,
      stage                   => 'pre',
    }

    service { 'logstash-web':
      ensure                  => 'stopped',
      enable                  => false,
      require                 => Package['logstash'],
    }

    $redis_cluster_string = join($redis_ip,'","')

    if $use_collectd {

      class { 'collectd':
        purge                 => true,
        recurse               => true,
        purge_config          => true,
        stage                 => 'pre',
      }
      class { 'collectd::plugin::load':
        stage                 => 'pre',
      }
      class { 'collectd::plugin::memory':
        stage                 => 'pre',
      }
      class { 'collectd::plugin::disk':
        stage                 => 'pre',
        disks                 => $collectd_disks,
      }
      class { 'collectd::plugin::interface':
        stage                 => 'pre',
      }
      class { 'collectd::plugin::df':
        stage                 => 'pre',
      }
      class { 'collectd::plugin::uptime':
        stage                 => 'pre',
      }
      class { 'collectd::plugin::network':
        timetolive            => '70',
        maxpacketsize         => '42',
        forward               => false,
        reportstats           => true,
        servers               => { '127.0.0.1' => {
          'port'              => '25826',
          },
        },
        stage                 => 'pre',
      }

      class { 'collectd::plugin::logfile':
        log_level             => 'info',
        log_file              => '/var/log/collectd.log'
        stage                 => 'pre',
      }

      file_fragment { 'input collectd':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => '  collectd { tags => ["collectd"] }
        ',
        order                 => 100,
      }
    }

    file_fragment { 'begin input':
      tag                     => "LS_CONFIG_CLIENT_${cluster_name}",
      content                 => 'input {
      ',
      order                   => 0,
      }

      file_fragment { 'input':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => $logstash_input,
        order                 => 200,
      }

      file_fragment { 'end_input':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => '
      }
      ',
      order                   => 398,
    }

    file_fragment { 'begin filter':
      tag                     => "LS_CONFIG_CLIENT_${cluster_name}",
      content                 => 'filter {
      ',
      order                   => 399,
      }

      file_fragment { 'filter':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => $logstash_filter,
        order                 => 500,
      }

      file_fragment { 'end filter':
        tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
        content               => '
      }
      ',
      order                   => 698,
    }

    file_fragment { 'output':
      tag                     => "LS_CONFIG_CLIENT_${cluster_name}",
      content                 => template('role_analytics/logstash_redis_output.erb'),
      order                   => 699,
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

    case $operatingsystem {
      'Ubuntu': {
        file_line { 'syslog_workaround':
          ensure              => "present",
          require             => Package['logstash'],
          path                => '/etc/init/logstash.conf',
          match               => 'setuid',
          line                => 'setuid root',
          notify              => [ Service["logstash"], Service["collectd"], ],
        }
      }
      'CentOS': {
        file_line { 'syslog_workaround':
          ensure              => "present",
          require             => Package['logstash'],
          path                => '/etc/sysconfig/logstash',
          match               => 'LS_USER=',
          line                => 'LS_USER=root',
          notify              => [ Service["logstash"], Service["collectd"], ],
        }
      }
    }

    if $use_dashboard {
      file {"/tmp/${dashboard_name}.json":
        ensure                => "present",
        path                  => "/tmp/${dashboard_name}.json",
        mode                  => "644",
        content               => template("role_analytics/${dashboard_name}.json.erb"),
        notify                => Exec['install_dashboard'],
      }
      exec { 'install_dashboard':
        command               => "/usr/bin/curl -XPUT http://${kibana_ip}:9200/kibana-int/dashboard/host-${hostname} -T /tmp/${dashboard_name}.json",
        refreshonly           => true,
      }
    }
    else {
      file {"/tmp/${dashboard_name}.json":
        ensure                => absent,
        path                  => "/tmp/${dashboard_name}.json",
      }
    }
}
}
