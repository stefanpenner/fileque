abook:
  desc: 'address book conversion queue'
  storage: file_system
  development:
    pathname: 'RAILS_ROOT + appname_development'

  production:
    pathname: '/path/to/shared/q'
