dns_push:
  desc: 'dns changes distribution queue'
  storage: file_system
  development:
    pathname: 'RAILS_ROOT + appname_development'

  production:
    pathname: '/path/to/shared/q'

