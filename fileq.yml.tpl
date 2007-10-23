fileq:
  desc: 'app fileq'
  storage: file_system
  development:
    pathname: '#{RAILS_ROOT}/tmp/fileq'

  production:
    pathname: '/path/to/shared/q'

