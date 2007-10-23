
class NamedPipeClientTests < Test::Unit::TestCase

  def setup
    FileUtils.mkdir 'test/tmp/'
    @tmp_fname1 = 'named.pipe'
    @tmp_name1 = 'test/tmp/' + @tmp_fname1
    tmp = Xxeo::NamedPipe.create_server(@tmp_name1)
    tmp.close
    @tmp_fname2 = 'named.out'
    @tmp_name2 = 'test/tmp/' + @tmp_fname2

    # Create separate process for server
    @pid = fork {
      np = Xxeo::NamedPipe.create_server(@tmp_name1)
      while true do
        data = np.wait_on_data(1)
        data ||= "TIMEOUT" # handle a timeout case
        File.open(@tmp_name2, 'w') do
          | f |
          f.write('GOT: ' + data)
        end
      end
    }
  end

  def teardown
    # Nuke the server process
    Process.kill(9, @pid)
    FileUtils.rm_rf 'test/tmp'
  end

  def test_create
    assert(Xxeo::NamedPipe.create_client(@tmp_name1))
  end

  def test_create_fail
    assert_raise RuntimeError do
      Xxeo::NamedPipe.create_client(@tmp_name1 + 'dldld')
    end

    File.chmod(0444, @tmp_name1)
    assert_raise RuntimeError do
      Xxeo::NamedPipe.create_client(@tmp_name1 + 'dldld')
    end
  end

  def test_messaging
    @np = Xxeo::NamedPipe.create_client(@tmp_name1)
    assert(@np)

    assert_send('test1')
    assert_send('test2')
    assert_send('test3')
    assert_send('test4')
    assert_send('test5')
  end

  def assert_send(msg)
    len = @np.send_mesg(msg)
    assert(len = msg.length)
    sleep(0.005) # 5 milliseconds should be more than enough time

    data = ''
    File.open(@tmp_name2, 'r') do
      | f |
      data = f.read
    end

    assert_equal('GOT: ' + msg, data)
  end

end

