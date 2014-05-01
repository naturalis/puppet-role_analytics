class role_analytics::logstash_indexer(
  $cluster_name,
	$version                       = '1.4',
){

  apt::source { 'logstash':
    location    => "http://packages.elasticsearch.org/logstash/${version}/debian",
    release     => 'stable',
    repos       => 'main',
    key         => '2BF6ED30',
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
      tag     => "LS_CONFIG_${cluster_name}",
      content => 'input {
',
      order   => 0,
  }
  file_fragment { 'end_input':
      tag     => "LS_CONFIG_${cluster_name}",
      content => '} 
',
      order   => 398,
  }
  file_fragment { 'begin filter':
      tag     => "LS_CONFIG_${cluster_name}",
      content => 'filter {
',
      order   => 399,
  }
  file_fragment { 'end filter':
      tag     => "LS_CONFIG_${cluster_name}",
      content => '}
',
      order   => 698,
  }
  file_fragment { 'begin output':
      tag     => "LS_CONFIG_${cluster_name}",
      content => "output { elasticsearch { cluster => '${cluster_name}' } }",
      order   => 699,
  }
  
  Role_analytics::Logstash_indexer::Indexer_config <<| tag == "${cluster_name}_indexer_config" |>> {
    before => File_concat['/etc/logstash/conf.d/indexer']
  }
    

  
  file_concat { '/etc/logstash/conf.d/indexer':
    tag     => "LS_CONFIG_${cluster_name}", # Mandatory
    owner   => 'logstash',       # Optional. Default to root
    group   => 'logstash',       # Optional. Default to root
    mode    => '0640',        # Optional. Default to 0644
    require => Package['logstash'],
    notify  => Service['logstash'],
  }


  define indexer_config(
    $type       = undef,
    $content    = "",
  ){
    
    #$order = 0
    if $type == 'input' {
      $order = 100 
    } elsif $type == 'filter'{
      $order = 400
    } elsif $type == 'output' {
      $order = 700
    } else {
      fail('The variable type should be input, filter or output')
    }


    file_fragment { $name :
      tag     => "LS_CONFIG_${cluster_name}",
      content => $content,
      order   => $order,
    }
  }
}