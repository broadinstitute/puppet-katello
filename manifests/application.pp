# Install and configure the katello application itself
class katello::application (
  Array[String] $package_names = $katello::package_names,
  Boolean $enable_ostree = $katello::enable_ostree,
  Boolean $enable_yum = $katello::enable_yum,
  Boolean $enable_file = $katello::enable_file,
  Boolean $enable_puppet = $katello::enable_puppet,
  Boolean $enable_docker = $katello::enable_docker,
  Boolean $enable_deb = $katello::enable_deb,

  Optional[Enum['SSLv23', 'TLSv1', '']] $cdn_ssl_version = $katello::cdn_ssl_version,
  Stdlib::Httpsurl $candlepin_url = $katello::candlepin_url,
  String $candlepin_oauth_key = $katello::candlepin_oauth_key,
  String $candlepin_oauth_secret = $katello::candlepin_oauth_secret,
  Stdlib::Httpsurl $pulp_url = $katello::pulp_url,
  Stdlib::Httpsurl $crane_url = $katello::crane_url,
  String $qpid_url = $katello::qpid_url,
  String $candlepin_event_queue = $katello::candlepin_event_queue,
  Optional[String] $proxy_host = $katello::proxy_url,
  Optional[Integer[0, 65535]] $proxy_port = $katello::proxy_port,
  Optional[String] $proxy_username = $katello::proxy_username,
  Optional[String] $proxy_password = $katello::proxy_password,
  Integer[0] $rest_client_timeout = $katello::rest_client_timeout,
) {
  include foreman
  include certs
  include certs::apache
  include certs::foreman
  include certs::pulp_client
  include certs::qpid
  include katello::qpid_client

  $candlepin_ca_cert = $certs::ca_cert
  $pulp_ca_cert = $certs::katello_server_ca_cert
  $crane_ca_cert = $certs::katello_server_ca_cert

  foreman_config_entry { 'pulp_client_cert':
    value          => $certs::pulp_client::client_cert,
    ignore_missing => false,
    require        => [Class['certs::pulp_client'], Foreman::Rake['db:seed']],
  }

  foreman_config_entry { 'pulp_client_key':
    value          => $certs::pulp_client::client_key,
    ignore_missing => false,
    require        => [Class['certs::pulp_client'], Foreman::Rake['db:seed']],
  }

  include foreman::plugin::tasks

  Class['certs', 'certs::ca', 'certs::apache'] ~> Class['apache::service']
  Class['certs', 'certs::ca', 'certs::qpid'] ~> Class['foreman::plugin::tasks']

  # Katello database seeding needs candlepin
  package { $package_names:
    ensure => installed,
  } ->
  file { "${foreman::plugin_config_dir}/katello.yaml":
    ensure  => file,
    owner   => 'root',
    group   => $foreman::group,
    mode    => '0640',
    content => template('katello/katello.yaml.erb'),
    notify  => [Class['foreman::service'], Foreman::Rake['db:seed'], Foreman::Rake['apipie:cache:index']],
  }

  foreman::config::apache::fragment { 'katello':
    ssl_content => file('katello/katello-apache-ssl.conf'),
  }
}
