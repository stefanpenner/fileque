#require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))


class FileQCreateDirTests < Test::Unit::TestCase

  def setup
    @fq = Xxeo::FileQ.new('test', {:dir => 'test/test_fq'})
    @fq.create_queue_dirs
  end

  def teardown
    FileUtils.rm_rf 'test/test_fq' 
  end

  def test_create
    assert(FileTest.directory?('test/test_fq')) 
    assert(FileTest.writable?('test/test_fq')) 
    assert(FileTest.readable?('test/test_fq/_lock')) 
    assert(FileTest.writable?('test/test_fq/_log')) 
    assert(FileTest.directory?('test/test_fq/_tmp')) 
    assert(FileTest.directory?('test/test_fq/que')) 
    assert(FileTest.directory?('test/test_fq/run')) 
    assert(FileTest.directory?('test/test_fq/pause')) 
    assert(FileTest.directory?('test/test_fq/done')) 
    assert(FileTest.directory?('test/test_fq/_err')) 
  end

  def test_create_verify
    assert(@fq.verify_store, 'Failed to verify')
    assert_equal('', @fq.last_error, 'Failed to have empty error message')
  end

  def test_bad_lock_file
    FileUtils.rm_rf('test/test_fq/_lock')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: file \'_lock\' does not exist', @fq.last_error, 'Failed to have correct error message')
  end

  #TODO: test lock file writable

  def test_bad_log_file
    FileUtils.rm_rf('test/test_fq/_log')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: file \'_log\' does not exist', @fq.last_error, 'Failed to have correct error message')
  end

  def test_bad_tmp_dir
    FileUtils.rm_rf('test/test_fq/_tmp')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: \'_tmp\' not a directory', @fq.last_error, 'Failed to have correct error message')
  end

  def test_bad_q_dir
    FileUtils.rm_rf('test/test_fq/que')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: \'que\' not a directory', @fq.last_error, 'Failed to have correct error message')
  end

  def test_bad_run_dir
    FileUtils.rm_rf('test/test_fq/run')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: \'run\' not a directory', @fq.last_error, 'Failed to have correct error message')
  end

  def test_bad_pause_dir
    FileUtils.rm_rf('test/test_fq/pause')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: \'pause\' not a directory', @fq.last_error, 'Failed to have correct error message')
  end

  def test_bad_done_dir
    FileUtils.rm_rf('test/test_fq/done')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: \'done\' not a directory', @fq.last_error, 'Failed to have correct error message')
  end

  def test_bad_err_dir
    FileUtils.rm_rf('test/test_fq/_err')
    assert(! @fq.verify_store, 'Failed to verify as false')
    assert_equal('bad queue dir: \'_err\' not a directory', @fq.last_error, 'Failed to have correct error message')
  end

end
