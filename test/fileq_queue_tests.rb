
class FileQQueueTests < Test::Unit::TestCase

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
  end

  def teardown
    FileUtils.rm_rf 'test/test_fq' 
  end

  def test_error_log
    @fq.log('busted')
    msgs = @fq.read_log
    assert_match(/ busted$/, msgs)
  end

  def test_insert_data
    assert_equal(0, @fq.length)

    job1 = @fq.insert_data('This is a test')
    assert(job1, 'invalid job1: nil : ' + @fq.read_log)

    y = @fq.all_lengths
    assert_equal({:que => 1}, y) #@fq.all_lengths)

    assert_equal(1, @fq.length)
    return
  end

  def test_multi_insert_data
    job1 = @fq.insert_data('This is a test1')
    assert(job1, 'invalid job1: false : ' + @fq.read_log)

    job2 = @fq.insert_data('This is a test2')
    assert(job2, 'invalid job2: false : ' + @fq.read_log)

    assert_equal({:que => 2}, @fq.all_lengths)

    assert_equal(2, @fq.length)
  end

  #  assert(FileTest.zero?('test/test_fq/_lock'))
  #  assert(FileTest.zero?('test/test_fq/_log'))
  #  assert_equal(0, Dir.glob('test/test_fq/_tmp/*').length, Dir.glob('test/test_fq/_tmp'))
  #  assert_equal(1, Dir.glob('test/test_fq/que/*').length)
  #  assert_equal(0, Dir.glob('test/test_fq/run/*').length)
  #  assert_equal(0, Dir.glob('test/test_fq/pause/*').length)
  #  assert_equal(0, Dir.glob('test/test_fq/done/*').length)
  #  assert_equal(0, Dir.glob('test/test_fq/_err/*').length)

  def test_insert_file
    job1 = @fq.insert_file(@tmp_name1)
    assert(job1, 'invalid job1: false : ' + @fq.read_log)

    assert_equal({:que => 1}, @fq.all_lengths)

    assert_equal(1, @fq.length)
  end
  
  def test_file_original_name
    job1 = @fq.insert_file(@tmp_name1)
    assert(job1, 'invalid job1: false : ' + @fq.read_log)

    assert_equal(job1.original_pathname, @tmp_name1)

    assert_equal(1, @fq.length)
  end


  def test_multi_insert_file
    job1 = @fq.insert_file(@tmp_name1)
    assert(job1, 'invalid job1: false : ' + @fq.read_log)

    job2 = @fq.insert_file(@tmp_name2)
    assert(job2, 'invalid job2: false : ' + @fq.read_log)

    assert_equal({:que => 2}, @fq.all_lengths)

    assert_equal(2, @fq.length)
  end

  def test_pull_none
    assert_equal(0, @fq.length)

    job = @fq.pull_job
    assert_equal(nil, job)
  end

  def test_pull_none_by_id
    assert_equal(0, @fq.length)

    job = @fq.pull_job('slslslslsl')
    assert_equal(nil, job)
  end


  # Test queueing

  def test_insert_pull_data_top_of_queue
    job1 = @fq.insert_data('This is a test 1')
    assert(job1.name, 'invalid job1: false : ' + @fq.read_log)
    job2 = @fq.insert_data('This is a test 2')
    assert(job1.name, 'invalid job2: false : ' + @fq.read_log)

    job = @fq.pull_job()

    assert_equal(job.name, job.name)

    assert_equal(job.data, 'This is a test 1')

    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :run => 1}, @fq.all_lengths)

    job.mark_done

    assert_equal(job.status, Xxeo::ST_DONE)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :done => 1}, @fq.all_lengths)
  end

  def test_pull_by_wrong_id
    job1 = @fq.insert_data('This is a test 1')
    assert(job1.name, 'invalid job1: false : ' + @fq.read_log)
    job2 = @fq.insert_data('This is a test 2')
    assert(job1.name, 'invalid job2: false : ' + @fq.read_log)

    assert_equal(2, @fq.length)

    job = @fq.pull_job('slslslslsl')
    assert_equal(nil, job)
  end

  def test_insert_pull_data_by_id
    job1 = @fq.insert_data('This is a test 1')
    assert(job1.name, 'invalid job1 false : ' + @fq.read_log)
    job2 = @fq.insert_data('This is a test 2')
    assert(job2.name, 'invalid job2 false : ' + @fq.read_log)

    job = @fq.pull_job(job1.name)

    assert_equal(job.name, job1.name)

    assert_equal(job.data, 'This is a test 1')

    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :run => 1}, @fq.all_lengths)

    job.mark_done

    assert_equal(job.status, Xxeo::ST_DONE)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :done => 1}, @fq.all_lengths)
  end


  def test_insert_pull_file
    job1 = @fq.insert_file(@tmp_name1)
    assert(job1.name, 'invalid job1 false : ' + @fq.read_log)
    job2 = @fq.insert_file(@tmp_name2)
    assert(job2.name, 'invalid job2: false : ' + @fq.read_log)

    assert_equal(2, @fq.length)

    job = @fq.pull_job()

    assert_equal(job1.name, job.name)

    assert_equal(job.data, @data1)
    assert(job.is_file?)
    assert(job.original_pathname, @tmp_name1)

    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :run => 1 }, @fq.all_lengths)

    job.mark_done

    assert_equal(job.status, Xxeo::ST_DONE)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :done => 1}, @fq.all_lengths)
  end

  def test_insert_pull_file_by_id1
    job1 = @fq.insert_file(@tmp_name1)
    assert(job1.name, 'invalid job1 false : ' + @fq.read_log)
    job2 = @fq.insert_file(@tmp_name2)
    assert(job2.name, 'invalid job2: false : ' + @fq.read_log)

    assert_equal(2, @fq.length)

    job = @fq.pull_job(job1.name)

    assert_equal(job1.name, job.name)

    assert_equal(job.data, @data1)

    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :run => 1}, @fq.all_lengths)

    job.mark_done

    assert_equal(job.status, Xxeo::ST_DONE)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :done => 1}, @fq.all_lengths)
  end

  def test_insert_pull_file_by_id2
    job1 = @fq.insert_file(@tmp_name1)
    assert(job1.name, 'invalid job1 false : ' + @fq.read_log)
    job2 = @fq.insert_file(@tmp_name2)
    assert(job2.name, 'invalid job2: false : ' + @fq.read_log)

    assert_equal(2, @fq.length)

    job = @fq.pull_job(job2.name)

    assert_equal(job2.name, job.name)

    assert_equal(job.data, @data2)

    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :run => 1}, @fq.all_lengths)

    job.mark_done

    assert_equal(job.status, Xxeo::ST_DONE)
    assert_equal(1, @fq.length)
    assert_equal({:que => 1, :done => 1}, @fq.all_lengths)
  end

  def test_insert_pull_data_and_file 
    job1 = @fq.insert_data('This is a test 1')
    assert(job1, 'invalid job1: ' + @fq.read_log)
    job2 = @fq.insert_file(@tmp_name1)
    assert(job2, 'invalid job2: ' + @fq.read_log)
    job3 = @fq.insert_data('This is a test 2')
    assert(job3, 'invalid job3: ' + @fq.read_log)
    job4 = @fq.insert_file(@tmp_name2)
    assert(job4, 'invalid job4: ' + @fq.read_log)

    assert_equal(4, @fq.length)

    jobX1 = @fq.pull_job
    assert(jobX1, 'invalid jobX1: ' + @fq.read_log)
    assert_equal(job1.name, jobX1.name)

    assert_equal(jobX1.data, 'This is a test 1')
    assert_equal(jobX1.status, Xxeo::ST_RUN)
    assert_equal(3, @fq.length)
    assert_equal({:que => 3, :run => 1}, @fq.all_lengths)
    jobX1.mark_done
    assert_equal(jobX1.status, Xxeo::ST_DONE)

    jobX2 = @fq.pull_job()
    assert_equal(job2.name, jobX2.name)

    assert_equal(jobX2.data, @data1)
    assert_equal(jobX2.status, Xxeo::ST_RUN)
    assert_equal(2, @fq.length)
    assert_equal({:run => 1, :que => 2, :done => 1}, @fq.all_lengths)
    jobX2.mark_done
    assert_equal(jobX1.status, Xxeo::ST_DONE)

    jobX3 = @fq.pull_job()
    assert_equal(job3.name, jobX3.name)

    assert_equal(jobX3.data, 'This is a test 2')
    assert_equal(jobX3.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:run => 1, :que => 1, :done => 2}, @fq.all_lengths)
    jobX3.mark_done
    assert_equal(jobX3.status, Xxeo::ST_DONE)

    jobX4 = @fq.pull_job()
    assert_equal(job4.name, jobX4.name)

    assert_equal(jobX4.data, @data2)
    assert_equal(jobX4.status, Xxeo::ST_RUN)
    assert_equal(0, @fq.length)
    assert_equal({:run => 1, :done => 3}, @fq.all_lengths)
    jobX4.mark_done
    assert_equal(jobX4.status, Xxeo::ST_DONE)

    assert_equal(0, @fq.length)
    assert_equal({:done => 4}, @fq.all_lengths)

  end

  def test_insert_pull_data_and_file_by_id 
    job1 = @fq.insert_data('This is a test 1')
    assert(job1, 'invalid job1: false : ' + @fq.read_log)
    job2 = @fq.insert_file(@tmp_name1)
    assert(job2, 'invalid job2: false : ' + @fq.read_log)
    job3 = @fq.insert_data('This is a test 2')
    assert(job3, 'invalid job3: false : ' + @fq.read_log)
    job4 = @fq.insert_file(@tmp_name2)
    assert(job4, 'invalid job4: false : ' + @fq.read_log)

    assert_equal(4, @fq.length)

    # How do we pull items from the queue?
    # Multiple consumers could happen
    jobX1 = @fq.pull_job(job1.name)
    assert_equal(job1.name, jobX1.name)

    assert_equal(jobX1.data, 'This is a test 1')
    assert_equal(jobX1.status, Xxeo::ST_RUN)
    assert_equal(3, @fq.length)
    assert_equal({:que => 3, :run => 1}, @fq.all_lengths)
    jobX1.mark_done
    assert_equal(jobX1.status, Xxeo::ST_DONE)

    jobX2 = @fq.pull_job(job2.name)
    assert_equal(job2.name, jobX2.name)

    assert_equal(jobX2.data, @data1)
    assert_equal(jobX2.status, Xxeo::ST_RUN)
    assert_equal(2, @fq.length)
    assert_equal({:done => 1, :que => 2, :run => 1}, @fq.all_lengths)
    jobX2.mark_done
    assert_equal(jobX1.status, Xxeo::ST_DONE)

    jobX3 = @fq.pull_job(job3.name)
    assert_equal(job3.name, jobX3.name)

    assert_equal(jobX3.data, 'This is a test 2')
    assert_equal(jobX3.status, Xxeo::ST_RUN)
    assert_equal(1, @fq.length)
    assert_equal({:done => 2, :que => 1, :run => 1}, @fq.all_lengths)
    jobX3.mark_done
    assert_equal(jobX3.status, Xxeo::ST_DONE)

    jobX4 = @fq.pull_job(job4.name)
    assert_equal(job4.name, jobX4.name)

    assert_equal(jobX4.data, @data2)
    assert_equal(jobX4.status, Xxeo::ST_RUN)
    assert_equal(0, @fq.length)
    assert_equal({:done => 3, :run => 1}, @fq.all_lengths)
    jobX4.mark_done
    assert_equal(jobX4.status, Xxeo::ST_DONE)

    assert_equal(0, @fq.length)
    assert_equal({:done => 4}, @fq.all_lengths)

  end


end
