require 'spec_helper'

describe 'katello::application' do
  on_os_under_test.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      let(:base_params) do
        {
          :package_names          => ['tfm-rubygem-katello'],
          :enable_ostree          => false,
          :enable_yum             => true,
          :enable_file            => true,
          :enable_puppet          => true,
          :enable_docker          => true,
          :enable_deb             => true,
          :cdn_ssl_version        => '',
          :candlepin_url          => 'https://foo.example.com:8443/candlepin',
          :candlepin_oauth_key    => 'candlepin',
          :candlepin_oauth_secret => 'candlepin-secret',
          :pulp_url               => 'https://foo.example.com/pulp/api/v2/',
          :crane_url              => 'https://foo.example.com:5000',
          :qpid_url               => 'amqp:ssl:localhost:5671',
          :candlepin_event_queue  => 'katello_event_queue',
          :proxy_host             => '',
          :proxy_port             => 8080,
          :proxy_username         => nil,
          :proxy_password         => nil,
          :rest_client_timeout    => 3600,
        }
      end

      context 'with explicit parameters' do
        context 'with base_params' do
          let (:params) { base_params }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_package('tfm-rubygem-katello') }
          it { is_expected.to contain_class('certs::qpid') }
          it { is_expected.to contain_class('katello::qpid_client') }

          it do
            is_expected.to create_foreman_config_entry('pulp_client_cert')
              .with_value('/etc/pki/katello/certs/pulp-client.crt')
              .that_requires(['Class[Certs::Pulp_client]', 'Foreman::Rake[db:seed]'])
          end

          it do
            is_expected.to create_foreman_config_entry('pulp_client_key')
              .with_value('/etc/pki/katello/private/pulp-client.key')
              .that_requires(['Class[Certs::Pulp_client]', 'Foreman::Rake[db:seed]'])
          end

          it do
            is_expected.to contain_service('httpd')
              .that_subscribes_to(['Class[Certs::Apache]', 'Class[Certs::Ca]'])
          end

          it do
            is_expected.to contain_file('/etc/foreman/plugins/katello.yaml')
              .that_notifies(['Class[Foreman::Service]', 'Exec[foreman-rake-db:seed]', 'Exec[restart_foreman]'])
          end

          it do
            is_expected.to create_foreman__config__apache__fragment('katello')
              .without_content()
              .with_ssl_content(%r{^<LocationMatch /rhsm\|/katello/api>$})
          end

          it do
            is_expected.to contain_class('certs::qpid')
              .that_notifies(['Class[Foreman::Plugin::Tasks]'])
          end

          it 'should generate correct katello.yaml' do
            verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
              ':katello:',
              '  :rest_client_timeout: 3600',
              '  :content_types:',
              '    :yum: true',
              '    :file: true',
              '    :deb: true',
              '    :puppet: true',
              '    :docker: true',
              '    :ostree: false',
              '  :candlepin:',
              '    :url: https://foo.example.com:8443/candlepin',
              '    :oauth_key: "candlepin"',
              '    :oauth_secret: "candlepin-secret"',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
              '  :pulp:',
              '    :url: https://foo.example.com/pulp/api/v2/',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
              '  :qpid:',
              '    :url: amqp:ssl:localhost:5671',
              '    :subscriptions_queue_address: katello_event_queue',
              '  :container_image_registry:',
              '    :crane_url: https://foo.example.com:5000',
              '    :crane_ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt'
            ])
          end
        end

        context 'with enable_ostree => true' do
          let :params do
            base_params.merge(:enable_ostree => true)
          end

          it { is_expected.to compile.with_all_deps }
        end

        context 'with rest client timeout' do
          let :params do
            base_params.merge(:rest_client_timeout => 4000)
          end

          it { is_expected.to compile.with_all_deps }

          it 'should generate correct katello.yaml' do
            verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
              ':katello:',
              '  :rest_client_timeout: 4000',
              '  :content_types:',
              '    :yum: true',
              '    :file: true',
              '    :deb: true',
              '    :puppet: true',
              '    :docker: true',
              '    :ostree: false',
              '  :candlepin:',
              '    :url: https://foo.example.com:8443/candlepin',
              '    :oauth_key: "candlepin"',
              '    :oauth_secret: "candlepin-secret"',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
              '  :pulp:',
              '    :url: https://foo.example.com/pulp/api/v2/',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
              '  :qpid:',
              '    :url: amqp:ssl:localhost:5671',
              '    :subscriptions_queue_address: katello_event_queue',
              '  :container_image_registry:',
              '    :crane_url: https://foo.example.com:5000',
              '    :crane_ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt'
            ])
          end
        end

        context 'with cdn_ssl_version' do
          let :params do
            base_params.merge(:cdn_ssl_version => 'TLSv1')
          end

          it { is_expected.to compile.with_all_deps }

          it 'should generate correct katello.yaml' do
            verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
              ':katello:',
              '  :cdn_ssl_version: TLSv1',
              '  :rest_client_timeout: 3600',
              '  :content_types:',
              '    :yum: true',
              '    :file: true',
              '    :deb: true',
              '    :puppet: true',
              '    :docker: true',
              '    :ostree: false',
              '  :candlepin:',
              '    :url: https://foo.example.com:8443/candlepin',
              '    :oauth_key: "candlepin"',
              '    :oauth_secret: "candlepin-secret"',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
              '  :pulp:',
              '    :url: https://foo.example.com/pulp/api/v2/',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
              '  :qpid:',
              '    :url: amqp:ssl:localhost:5671',
              '    :subscriptions_queue_address: katello_event_queue',
              '  :container_image_registry:',
              '    :crane_url: https://foo.example.com:5000',
              '    :crane_ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt'
            ])
          end
        end

        context 'when http proxy parameters are specified' do
          let(:params) do
            base_params.merge(
              :proxy_host     => 'http://myproxy.org',
              :proxy_port     => 8888,
              :proxy_username => 'admin',
              :proxy_password => 'secret_password',
            )
          end

          it 'should generate correct katello.yaml' do
            verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
              ':katello:',
              '  :rest_client_timeout: 3600',
              '  :content_types:',
              '    :yum: true',
              '    :file: true',
              '    :deb: true',
              '    :puppet: true',
              '    :docker: true',
              '    :ostree: false',
              '  :candlepin:',
              '    :url: https://foo.example.com:8443/candlepin',
              '    :oauth_key: "candlepin"',
              '    :oauth_secret: "candlepin-secret"',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
              '  :pulp:',
              '    :url: https://foo.example.com/pulp/api/v2/',
              '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
              '  :qpid:',
              '    :url: amqp:ssl:localhost:5671',
              '    :subscriptions_queue_address: katello_event_queue',
              '  :container_image_registry:',
              '    :crane_url: https://foo.example.com:5000',
              '    :crane_ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
              '  :cdn_proxy:',
              '    :host: http://myproxy.org',
              '    :port: 8888',
              '    :user: "admin"',
              '    :password: "secret_password"'
            ])
          end
        end
      end

      context 'with inherited parameters' do
        let :pre_condition do
          <<-EOS
          class {'::katello':
            candlepin_oauth_key    => 'candlepin',
            candlepin_oauth_secret => 'candlepin-secret',
          }
          EOS
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_package('tfm-rubygem-katello') }
        it { is_expected.to create_package('katello') }
        it do
          is_expected.to contain_package('tfm-rubygem-katello')
            .that_requires('Class[candlepin]')
        end

        it 'should generate correct katello.yaml' do
          verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
            ':katello:',
            '  :rest_client_timeout: 3600',
            '  :content_types:',
            '    :yum: true',
            '    :file: true',
            '    :deb: true',
            '    :puppet: true',
            '    :docker: true',
            '    :ostree: false',
            '  :candlepin:',
            '    :url: https://foo.example.com:8443/candlepin',
            '    :oauth_key: "candlepin"',
            '    :oauth_secret: "candlepin-secret"',
            '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
            '  :pulp:',
            '    :url: https://foo.example.com/pulp/api/v2/',
            '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
            '  :qpid:',
            '    :url: amqp:ssl:localhost:5671',
            '    :subscriptions_queue_address: katello_event_queue',
            '  :container_image_registry:',
            '    :crane_url: https://foo.example.com:5000',
            '    :crane_ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt'
          ])
        end
      end

    end
  end
end
