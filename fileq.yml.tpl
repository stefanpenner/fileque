dns_push:
  desc: 'dns changes distribution queue'
  storage: file_system
  development:
    pathname: '#ENV[RAILS_ROOT]/tmp/fileq'

  production:
    pathname: '/path/to/shared/q'

