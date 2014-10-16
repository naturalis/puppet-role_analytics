# == Class: role_analytics::collectd_repos
#
class role_analytics::collectd_repos {

  case $::osfamily {
    debian: {
      case $::lsbdistcodename {
        precise: { include apt
                   apt::ppa { 'ppa:croscondevops/collectd-latest':
                   }
                 }
        default: {
                 }
      }
    }

    redhat: {
      yumrepo { 'pakk':
        descr    => 'pakk Centos Repo',
        baseurl  => "http://pakk.96b.it/repositories/el6/x86_64/",
        gpgcheck => 1,
        gpgkey   => 'http://pakk.96b.it/RPM-GPG-KEY-pakk',
        enabled  => 1,
      }
    }
  }
}
