
class NamedPipeServerTests < Test::Unit::TestCase

  def setup
    FileUtils.mkdir 'test/tmp/'
    @tmp_fname1 = 'named.pipe1'
    @tmp_name1 = 'test/tmp/' + @tmp_fname1
    FileUtils.touch @tmp_name1

    @tmp_fname2 = 'named.pipe2'
    @tmp_name2 = 'test/tmp/' + @tmp_fname2

    #@np = NamedPipe.create_server(@tmp_name1)
  end

  def teardown
    FileUtils.rm_rf 'test/tmp'
  end

  def test_create_newpipe
    assert(Xxeo::NamedPipe.create_server(@tmp_name2))
  end

  def test_create_existing
    assert(Xxeo::NamedPipe.create_server(@tmp_name1))
  end


  def test_create_fail
    ## Bad permission
    #File.chmod(0444, @tmp_name1)
    #assert_raise RuntimeError do
    #  Xxeo::NamedPipe.create_server(@tmp_name1)
    #end

    # No create on non-existant file
    assert_raise RuntimeError do
      Xxeo::NamedPipe.create_server(@tmp_name2, {:create => 'no'})
    end
  end

  def test_same_process_trigger
    nps = Xxeo::NamedPipe.create_server(@tmp_name1)
    assert(nps)

    npc = Xxeo::NamedPipe.create_client(@tmp_name1)
    assert(npc)

    test_msg = 'testTESTtestTEST'
    npc.send_mesg(test_msg)

    data = nps.wait_on_data(0.1)

    assert_equal(test_msg, data)
  end

  def test_time_out
    start = Time.now
    np = Xxeo::NamedPipe.create_server(@tmp_name1)
    assert(np)
    data = np.wait_on_data(0.010)
    finish = Time.now

    diff = finish - start

    # Assert really close
    assert_in_delta(0.010, diff, 0.01)
  end

end

