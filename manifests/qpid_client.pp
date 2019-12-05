# Install and configure a qpid client.
# This is used by the Katello rails app to connect to the
# qpid message broker.
class katello::qpid_client {
  include kcerts
  include kcerts::qpid

  class { 'qpid::client':
    ssl                    => true,
    ssl_cert_name          => 'broker',
    ssl_cert_db            => $kcerts::qpid::nss_db_dir,
    ssl_cert_password_file => $kcerts::qpid::nss_db_password_file,
    require                => Class['kcerts', 'kcerts::qpid'],
  }

  contain qpid::client
}
