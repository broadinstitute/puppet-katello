# Katello qpid Config
class katello::qpid (
  String $katello_user = $katello::user,
  String $candlepin_event_queue = $katello::candlepin_event_queue,
  String $candlepin_qpid_exchange = $katello::candlepin_qpid_exchange,
  Integer[0, 5000] $wcache_page_size = $katello::qpid_wcache_page_size,
  String $interface = $katello::qpid_interface,
  String $hostname = $katello::qpid_hostname,
) {
  include kcerts
  include kcerts::qpid

  class { 'qpid':
    ssl                    => true,
    ssl_cert_db            => $kcerts::qpid::nss_db_dir,
    ssl_cert_password_file => $kcerts::qpid::nss_db_password_file,
    ssl_cert_name          => 'broker',
    acl_content            => file('katello/qpid_acls.acl'),
    interface              => $interface,
    wcache_page_size       => $wcache_page_size,
    subscribe              => Class['kcerts', 'kcerts::qpid'],
  }

  contain qpid

  User<|title == $katello_user|>{groups +> 'qpidd'}

  qpid::config::queue { $candlepin_event_queue:
    ssl_cert => $kcerts::qpid::client_cert,
    ssl_key  => $kcerts::qpid::client_key,
    hostname => $hostname,
  }

  qpid::config::bind { ['entitlement.created', 'entitlement.deleted', 'pool.created', 'pool.deleted', 'compliance.created', 'system_purpose_compliance.created']:
    queue    => $candlepin_event_queue,
    exchange => $candlepin_qpid_exchange,
    ssl_cert => $kcerts::qpid::client_cert,
    ssl_key  => $kcerts::qpid::client_key,
    hostname => $hostname,
  }
}
