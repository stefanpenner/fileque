
class FileQFindTests < Test::Unit::TestCase

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
  end

  def teardown
    FileUtils.rm_rf 'test/test_fq' 
  end

  def test_find
    assert(@fq.find_job(@job1.name))
  end

  def test_find_fail
    assert(!@fq.find_job('dldldld'))
  end

  def test_find_que
    job = @fq.find_job(@job1.name)
    assert(job)
    assert_equal(job.status, Xxeo::ST_QUEUED)
    assert_equal(false, job.own?)
  end

  def test_find_run
    @job1.pull
    job = @fq.find_job(@job1.name)
    assert(job)
    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(false, job.own?)
  end

  def test_find_and_run
    job = @fq.find_job(@job1.name)
    assert(job)
    assert(job.pull, @fq.read_log)
    assert_equal(job.status, Xxeo::ST_RUN)
    assert_equal(true, job.own?)
  end

  def test_find_done
    @job1.pull
    @job1.mark_done
    job = @fq.find_job(@job1.name)
    assert(job)
    assert_equal(job.status, Xxeo::ST_DONE)
    assert_equal(false, job.own?)
  end

  def test_find_err
    @job1.pull
    @job1.mark_error
    job = @fq.find_job(@job1.name)
    assert(job)
    assert_equal(job.status, Xxeo::ST_ERROR)
    assert_equal(false, job.own?)
  end

end
