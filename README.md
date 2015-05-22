puppet-role_analytics
===================

Puppet module to install analytics tools.

For more information using this tool:

Parameters
-------------
All parameters are read from hiera

Classes
-------------
- elasticsearch cluster
- logstash client
- logstash indexer
- redis server

Dependencies
-------------
- stdlib
- elasticsearch-logstash
- ispavailability-file_concat

Limitations
-------------
This module has been built on and tested against Puppet 3.4.3 and higher.

The module has been tested on:
- Ubuntu 12.04
- Ubuntu 14.04
- CentOS 6.4
- CentOS 6.5

Authors
-------------
Author Name <atze.devries@naturalis.nl>
