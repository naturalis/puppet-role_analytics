class role_analytics::elasticsearch_cluster(
	$es_version   = '1.0.1',
  $shards       = '3',
  $replicas     = '0',
  $es_memory_gb = false,
  $es_data_dir  = '/data/elasticsearch',
  $es_modules   = ['xyu/elasticsearch-whatson/0.1.3'],
){
	
  include stdlib

  $cluster_name = $role_analytics::params::cluster_name

  if !($es_memory_gb) {
    $es_memory_gb_real = floor($::memorysize_mb/2000)
  }else{
    $es_memory_gb_real = $es_memory_gb
  }

  #common::directory_structure{ $es_data_dir :
  #  user    => 'elasticsearch',
  #  mode    => '0750',
  #  notify  => Service['elasticsearch'],
  #}
  
  class{ 'elasticsearch':
    package_url               => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_version}.deb",
    config                    => {
        'node'                  => {
          'name'                => $::hostname
        },
        'index'                 => {
          'number_of_shards'    => $shards,
          'number_of_replicas'  => $replicas
        },
        'cluster'               => {
          'name'                => $cluster_name
        }
      },
    java_install              => true,
    init_defaults             => {
        'ES_HEAP_SIZE'          => "${$es_memory_gb_real}g",
        'DATA_DIR'              => $es_data_dir
    },
  }

  elasticsearch::plugin{ $es_modules :
    module_dir => 'head',
  }
    

}