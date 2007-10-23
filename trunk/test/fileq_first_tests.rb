#require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class FileQFirstTest < Test::Unit::TestCase

  def setup
    FileUtils.mkdir 'test/test_fq' 
    FileUtils.touch 'test/test_fq/_lock' 
    FileUtils.touch 'test/test_fq/_log' 
    FileUtils.mkdir 'test/test_fq/_tmp' 
    FileUtils.mkdir 'test/test_fq/que' 
    FileUtils.mkdir 'test/test_fq/run' 
    FileUtils.mkdir 'test/test_fq/pause' 
    FileUtils.mkdir 'test/test_fq/done' 
    FileUtils.mkdir 'test/test_fq/_err' 
    File.open('test/test_fq/lock', "w") { |f| f.close }
  end

  def teardown
    FileUtils.rm_rf 'test/test_fq' 
  end

  def test_instantiate
    fq = Xxeo::FileQ.new('test', { :dir => 'test/test_fq'})
    assert_not_nil(fq)
  end

  def test_instantiate_verify
    fq = Xxeo::FileQ.new('test', { :dir => 'test/test_fq'})
    assert_not_nil(fq)
    assert(fq.verify_store)
  end

end
