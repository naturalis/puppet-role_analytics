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
  $host_links                       = undef,
){

  case $operatingsystem {
    "Ubuntu": {
      if $operatingsystemrelease == '12.04' or $operatingsystemrelease == '14.04' {

          $redis_cluster_members = query_nodes("Class[Role_analytics::Redis]{cluster_name='${cluster_name}'}",ec2_public_ipv4)
          $redis_cluster_string = join($redis_cluster_members,'","')

          apt::source { 'logstash':
            location                => "http://packages.elasticsearch.org/logstash/${version}/debian",
            release                 => 'stable',
            repos                   => 'main',
            key                     => 'D88E42B4',
            key_server              => 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch',
            include_src             => false,
          }

          package { 'logstash' :
            ensure                  => present,
            require                 => Apt::Source['logstash'],
          }

          if $use_collectd {

            class { '::collectd':
              purge                 => true,
              recurse               => true,
              purge_config          => true,
            }

            class { 'collectd::plugin::network':
              server                => '127.0.0.1',
            }
            class { 'collectd::plugin::load': }
            class { 'collectd::plugin::memory': }
            class { 'collectd::plugin::disk':
              disks                 => $collectd_disks,
            }
            class { 'collectd::plugin::interface': }
            class { 'collectd::plugin::df': }
            class {'collectd::plugin::uptime': }

            file_fragment { 'input collectd':
              tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
              content               => '  collectd { tags => ["collectd"] }
        ',
              order                 => 100,
            }
          }

          service {'logstash':
            ensure                  => running,
            enable                  => true,
            require                 => Package['logstash'],
            hasrestart              => true,
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

          file_line { 'syslog_workaround':
            ensure                  => "present",
            require                 => Package['logstash'],
            path                    => '/etc/init/logstash.conf',
            match                   => 'setgid',
            line                    => 'setgid adm',
            notify                  => Exec['update_groups'],
          }

          exec { 'update_groups':
            command                 => "/usr/sbin/usermod -a -G adm logstash && /etc/init.d/logstash restart && /etc/init.d/collectd restart",
            refreshonly             => true,
            require                 => Package['logstash'],
            unless                  => "/usr/bin/groups logstash | grep adm"
          }

          if $use_dashboard {
            file {"/tmp/${dashboard_name}.json":
              ensure                => "present",
              mode                  => "644",
              content               => template("role_analytics/${dashboard_name}.json.erb"),
              notify                => Exec['install_dashboard'],
          }
            exec { 'install_dashboard':
              command               => "/usr/bin/curl -XPUT http://${kibana_ip}:9200/kibana-int/dashboard/host-${hostname} -T /tmp/${dashboard_name}.json",
              refreshonly           => true,
            }
          }
      }
      else {
        notify { "Logging is not working with Ubuntu '$operatingsystemrelease' so disabled": }
      }
    }
    "CentOS":  {
    # $redis_cluster_members = query_nodes("Class[Role_analytics::Redis]{cluster_name='${cluster_name}'}",ec2_public_ipv4)
    # $redis_cluster_string = join($redis_cluster_members,'","')
      $redis_cluster_string = [ "10.42.1.118","10.42.1.116","10.42.1.117" ]

      yumrepo { 'logstash':
        descr    => 'Logstash Centos Repo',
        baseurl  => "http://packages.elasticsearch.org/logstash/${version}/centos",
        gpgcheck => 1,
        gpgkey   => 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch',
        enabled  => 1,
      }

      package { 'logstash' :
        ensure                  => present,
        require                 => yumrepo['logstash'],
      }

      if $use_collectd {

#        class { '::collectd':
#          purge                 => true,
#          recurse               => true,
#          purge_config          => true,
#        }

#        class { 'collectd::plugin::network':
#          server                => '127.0.0.1',
#        }
#        class { 'collectd::plugin::load': }
#        class { 'collectd::plugin::memory': }
#        class { 'collectd::plugin::disk':
#          disks                 => $collectd_disks,
#        }
#        class { 'collectd::plugin::interface': }
#        class { 'collectd::plugin::df': }
#        class {'collectd::plugin::uptime': }

        file_fragment { 'input collectd':
          tag                   => "LS_CONFIG_CLIENT_${cluster_name}",
          content               => '  collectd { tags => ["collectd"] }
    ',
          order                 => 100,
        }
      }

      service {'logstash':
        ensure                  => running,
        enable                  => true,
        require                 => Package['logstash'],
        hasrestart              => true,
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

      file_line { 'syslog_workaround':
        ensure                  => "present",
        require                 => Package['logstash'],
        path                    => '/etc/init/logstash.conf',
        match                   => 'setgid',
        line                    => 'setgid adm',
        notify                  => Exec['update_groups'],
      }

      exec { 'update_groups':
        command                 => "/usr/sbin/usermod -a -G adm logstash && /etc/init.d/logstash restart && /etc/init.d/collectd restart",
        refreshonly             => true,
        require                 => Package['logstash'],
        unless                  => "/usr/bin/groups logstash | grep adm"
      }

      if $use_dashboard {
        file {"/tmp/${dashboard_name}.json":
          ensure                => "present",
          mode                  => "644",
          content               => template("role_analytics/${dashboard_name}.json.erb"),
          notify                => Exec['install_dashboard'],
      }
        exec { 'install_dashboard':
          command               => "/usr/bin/curl -XPUT http://${kibana_ip}:9200/kibana-int/dashboard/host-${hostname} -T /tmp/${dashboard_name}.json",
          refreshonly           => true,
        }
      }

    #  notify { "Logging is not working with CentOS '$operatingsystemrelease' so disabled": }
    }

    "default":  {
      notify { "Logging is not working with '$operatingsystem' - '$operatingsystemrelease' so disabled": }
    }
  }
}
