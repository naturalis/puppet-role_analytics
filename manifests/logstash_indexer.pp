role_analytics::logstash_indexer(
	$version                       = '1.4.0',
  $logstash_install_directory    = '/opt/logstash',
){

  common::directory_structure{ $logstash_install_directory : }
  common::directory_structure{ '/etc/logstash' : }

  common::download_extract{ "logstash-${version}.tar.gz":
    link        => "https://download.elasticsearch.org/logstash/logstash/logstash-${version}.tar.gz",
    extract_dir => $logstash_install_directory,
    creates     => "${logstash_install_directory}/logstash-${version}", 
    require     => Common::Directory_structure[$logstash_install_directory],
  }

  file {'/etc/logstash/logstash_indexer.conf':
    ensure  => present,
    mode    => '0640',
    content => template('role_analytics/logstash_indexer.conf.erb'),
    require => Common::Directory_structure['/etc/logstash'],
  }




  define indexer_config::(
    $type       = undef,
    $content    = undef,
  ) {
    
    $order = 0
    if $type == 'input' {
      $order = 100 
    } elsif $type == 'filter'{
      $order = 400
    } elsif $type == 'output' {
      $order = 700
    } else {
      Fail('The variable type should be input, filter or output')
    }


    file_fragment { $name:
      tag => "LS_CONFIG_${::fqdn}",
      content => $content,
      order =>   $order,
    }


  }

}