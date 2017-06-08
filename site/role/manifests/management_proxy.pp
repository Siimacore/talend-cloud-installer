#
#
class role::management_proxy(

  $elasticsearch_host,
  $elasticsearch_url_scheme = 'https',
  $auth_realm               = 'Elasticsearch',
  $auth_username            = undef,
  $auth_password            = undef,

) {

  include ::profile::base
  include ::profile::web::nginx

  $elasticsearch_url = "${elasticsearch_url_scheme}://${elasticsearch_host}"

  $create_resolvers_command = 'echo resolver \
  $(awk \'BEGIN{ORS=" "} $1=="nameserver" {print $2}\' /etc/resolv.conf) "valid=5s;" \
  > /etc/nginx-resolvers.conf'
  exec { 'create nginx resolvers.conf':
    command => $create_resolvers_command,
    creates => '/etc/nginx-resolvers.conf',
    before  => Nginx::Resource::Vhost['es-sys'],
  }

  if $auth_username and $auth_password {
    $htpasswd_file = '/etc/nginx/.htpasswd'
    file { $htpasswd_file:
      ensure => present,
    }

    $password = pw_hash($auth_password, 'SHA-512', fqdn_rand_string(10))
    file_line { 'Elasticsearch basic auth':
      ensure  => present,
      path    => $htpasswd_file,
      line    => "${auth_username}:${password}",
      match   => "^${auth_username}\\:",
      replace => false,
      before  => Nginx::Resource::Vhost['es-sys'],
    }

    $auth_basic           = $auth_realm
    $auth_basic_user_file = $htpasswd_file
  } else {
    $auth_basic           = undef
    $auth_basic_user_file = undef
  }

  nginx::resource::vhost { 'es-sys':
    server_name          => ['_'],
    listen_port          => '8080',
    auth_basic           => $auth_basic,
    auth_basic_user_file => $auth_basic_user_file,
    proxy                => '$proxy_url',
    location_raw_append  => ['proxy_pass_request_headers off;'],
    location_raw_prepend => [
      'include /etc/nginx-resolvers.conf;',
      "set \$proxy_url ${elasticsearch_url};"
    ],
  }

}
