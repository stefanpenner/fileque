
class FileQJobTests < Test::Unit::TestCase

  def setup
    @fq = Xxeo::FileQ.new('test', {:dir => 'test/test_fq'})
    @fq.create_queue_dirs

    @tmp_fname1 = 'tmp_file1'
    @tmp_name1 = 'test/test_fq/' + @tmp_fname1
    @data1 = "blah blah1\nblah blah1\n"
    File.open(@tmp_name1, "w") { |f| f.write(@data1) }

    @tmp_fname2 = 'tmp_file2'
    @tmp_name2 = 'test/test_fq/' + @tmp_fname2
    @data2 = "blah blah2\nblah blah2\n"
    File.open(@tmp_name2, "w") { |f| f.write(@data2) }

    @job1 = @fq.insert_data('This is a test')
    @job2 = @fq.insert_file(@tmp_name1)
    @job3 = @fq.insert_file(@tmp_name2)
  end

  def teardown
    FileUtils.rm_rf 'test/test_fq' 
  end

  def test_status_getter_plain
    assert_equal(@job1.status, Xxeo::ST_QUEUED)
    assert_equal(@job2.status, Xxeo::ST_QUEUED)
    assert_equal(@job3.status, Xxeo::ST_QUEUED)
  end

  def test_pull_job
    job1 = @fq.pull_job(@job1.name)
    assert(job1)
  end

  def test_pull_job_via_instance
    assert(@job1.pull)
  end


  # This is a rare case, the typical cycle is 
  # Process 1 -> insert into que
  # Process 2 -> pull from que, mark_done/err
  def test_pull_job_via_instance_twice
    assert(@job1.pull)
    assert(@job1.pull)
  end

  def test_pull_job_via_instance_fail
    assert(@job1.pull)
    @job1.mark_done
    assert(!@job1.pull)
  end

  def test_status_mesg_setter_bad
    assert_raise Xxeo::WrongStatus do
      @job1.status_mesg = 'blah'
    end
    assert_raise Xxeo::WrongStatus do
      @job1.mark_done
    end
  end

  def test_status_mesg_setter
    assert(@job1.pull)
    @job1.status_mesg = 'pushing now'

    assert_equal(@job1.status_mesg, 'pushing now')
  end

  def test_logger
    assert(@job1.pull)
    assert(@job1.log('doing push now'))
  end

  def test_log_reader
    assert(@job1.pull)
    assert(@job1.log('doing push now'))
    assert_match(/ doing push now$/, @job1.read_log)
  end

  def test_mark_done
    @job1.pull
    @job1.mark_done

    assert_equal(@job1.status, Xxeo::ST_DONE)
    assert_equal(@job2.status, Xxeo::ST_QUEUED)
    assert_equal(@job3.status, Xxeo::ST_QUEUED)

    assert_equal({:done => 1, :que => 2}, @fq.all_lengths)

    assert_equal(2, @fq.length)
  end

  def test_mark_err
    @job1.pull
    @job1.mark_error

    assert_equal(@job1.status, Xxeo::ST_ERROR)
    assert_equal(@job2.status, Xxeo::ST_QUEUED)
    assert_equal(@job3.status, Xxeo::ST_QUEUED)

    assert_equal({:que => 2, :_err => 1}, @fq.all_lengths)

    assert_equal(2, @fq.length)
  end

  def test_owning_pid1
    @job1.pull

    @job2.pull
    @job2.mark_done

    @job3.pull
    @job3.mark_done

    assert_equal(@job1.owning_pid, $$)
    assert_equal(@job2.owning_pid, nil)
    assert_equal(@job3.owning_pid, nil)
  end

  def test_owning_pid2
    @job1.pull

    assert_equal(@job1.owning_pid, $$)
    assert_equal(@job2.owning_pid, nil)
    assert_equal(@job3.owning_pid, nil)
  end

  def test_own_yes
    @job1.pull

    @job2.pull
    @job2.mark_done

    @job3.pull
    @job3.mark_done

    assert(@job1.own?)
    assert(!@job2.own?)
    assert(!@job3.own?)
  end

  def test_own_not
    @job1.pull

    @job2.pull
    @job2.mark_done

    @job3.pull
    @job3.mark_done

    job1 = @fq.find_job(@job1.name)
    job2 = @fq.find_job(@job2.name)
    job3 = @fq.find_job(@job3.name)

    assert(!job1.own?)
    assert(!job2.own?)
    assert(!job3.own?)
  end


  def test_status_all1
    @job1.pull

    @job2.pull
    @job2.mark_error

    @job3.pull
    @job3.mark_done

    assert_equal(@job1.status_all, [Xxeo::ST_RUN, $$, ''])
    assert_equal(@job2.status_all, [Xxeo::ST_ERROR, nil, ''])
    assert_equal(@job3.status_all, [Xxeo::ST_DONE, nil, ''])
  end

  def test_status_all2
    @job1.pull
    assert_equal(@job1.status_all, [Xxeo::ST_RUN, $$, ''])
    assert_equal(@job2.status_all, [Xxeo::ST_QUEUED, nil, ''])
    assert_equal(@job3.status_all, [Xxeo::ST_QUEUED, nil, ''])
  end

  # TODO: test a crash and cleanup
  # TODO: test a fork and owning pid of different process

  def test_is_file
    assert(!@job1.is_file?)
    assert(@job2.is_file?)
    assert(@job3.is_file?)
  end

  def test_file_original_name
    assert(@job2.is_file?)
    assert_equal(@job2.original_pathname, @tmp_name2)
  end

  def test_file_original_name
    assert(!@job1.is_file?)
    assert_equal(@job1.original_pathname, nil)
  end

end
