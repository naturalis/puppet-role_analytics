class role_analytics::logstash_indexer(
  $cluster_name,
	$version          = '1.4',
  $logstash_input   = '# No input configured. Use Puppet variable',
  $logstash_filter  = '# No filter configured. Use Puppet variable',
){

  apt::source { 'logstash':
    location    => "http://packages.elasticsearch.org/logstash/${version}/debian",
    release     => 'stable',
    repos       => 'main',
    key_server  => 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch',
    include_src => false,
  }

  package { 'logstash' :
    ensure  => present,
    require => Apt::Source['logstash'],
  }


  service {'logstash':
    ensure  => running,
    require => Package['logstash'],
  }


  file_fragment { 'begin input':
      tag     => "LS_CONFIG_CLIENT_${cluster_name}",
      content => 'input {
',
      order   => 0,
  }

  file_fragment { 'filter':
    tag     => "LS_CONFIG_CLIENT_${cluster_name}",
    content => $logstash_input,
    order   => 200,
  }

  file_fragment { 'end_input':
      tag     => "LS_CONFIG_CLIENT_${cluster_name}",
      content => '}
',
      order   => 398,
  }
  file_fragment { 'begin filter':
      tag     => "LS_CONFIG_CLIENT_${cluster_name}",
      content => 'filter {
',
      order   => 399,
  }
  file_fragment { 'filter':
    tag     => "LS_CONFIG_CLIENT_${cluster_name}",
    content => $logstash_filter,
    order   => 500,
  }
  file_fragment { 'end filter':
      tag     => "LS_CONFIG_CLIENT_${cluster_name}",
      content => '}
',
      order   => 698,
  }

  #file_fragment { 'output':
  #    tag     => "LS_CONFIG_CLIENT_${cluster_name}",
  #    content => "output { elasticsearch { cluster => '${cluster_name}' } }",
  #    order   => 699,
  #}

  File_fragment <<| tag == "LS_CONFIG_CLIENT_${cluster_name}" |>> {
    before => File_concat['/etc/logstash/conf.d/logstash_client.conf']
  }

  file_concat { '/etc/logstash/conf.d/logstash_client.conf':
    tag     => "LS_CONFIG_CLIENT_${cluster_name}", # Mandatory
    owner   => 'logstash',       # Optional. Default to root
    group   => 'logstash',       # Optional. Default to root
    mode    => '0640',        # Optional. Default to 0644
    require => Package['logstash'],
    notify  => Service['logstash'],
  }
}
