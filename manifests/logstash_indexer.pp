class role_analytics::logstash_indexer(
	$version                       = '1.4',
){


  apt::source { 'logstash':
    location    => "http://packages.elasticsearch.org/logstash/${version}/debian",
    release     => 'stable',
    repos       => 'main',
    key         => '2BF6ED30',
    key_server  => 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch',
  }

  package { 'logstash' :
    ensure  => present,
    require => Apt::Source['logstash'],
  }


  service {'logstash':
    ensure  => running,
    require => Package['logstash'],
  }

  #file {'/etc/logstash/conf.d/logstash_indexer.conf':
  #  ensure  => present,
  #  mode    => '0640',
  #  content => template('role_analytics/logstash_indexer.conf.erb'),
  #  require => Package['logstash'],
  #  notify  => Service['logstash']
  #}



  file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => 'input {',
      order   => 0,
  }
  file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => '}',
      order   => 398,
  }
  file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => 'filter {',
      order   => 399,
  }
  file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => '}',
      order   => 698,
  }
  file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => 'output {',
      order   => 699,
  }
  file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => '}',
      order   => 999,
  }




  define indexer_config(
    $type       = undef,
    $content    = "",
  ){
    
    $order = 0
    if $type == 'input' {
      $order = 100 
    } elsif $type == 'filter'{
      $order = 400
    } elsif $type == 'output' {
      $order = 700
    } else {
      fail('The variable type should be input, filter or output')
    }


    file_fragment { '/etc/logstash/conf.d/logstash_indexer.conf':
      tag     => "LS_CONFIG_${::fqdn}",
      content => $content,
      order   => $order,
      notify  => Service['logstash'],
      require => Package['logstash'],
    }
  }
}