
class LockFileTests < Test::Unit::TestCase

  def setup
    FileUtils.mkdir 'test/tmp/'
    @tmp_fname1 = 'lock.file'
    @tmp_name1 = 'test/tmp/' + @tmp_fname1
    FileUtils.touch @tmp_name1

    @tmp_fname2 = 'junk.file'
    @tmp_name2 = 'test/tmp/' + @tmp_fname2
    FileUtils.touch @tmp_name2
  end

  def teardown
    FileUtils.rm_rf 'test/tmp'
  end

  def test_create
    assert(Xxeo::LockFile.new(@tmp_name1))
  end

  def test_create_fail
    assert_raise RuntimeError do
      Xxeo::LockFile.new('dldldld')
    end

    File.chmod(0444, @tmp_name1)
    assert_raise RuntimeError do
      Xxeo::LockFile.new(@tmp_name1)
    end
  end

  def test_lock_unlock
    lf = Xxeo::LockFile.new(@tmp_name1)
    assert(lf)

    lf.lock
    assert(lf.locked?)
    assert_equal(1, lf.lock_count)
    lf.unlock

    assert(!lf.locked?)
    assert_equal(0, lf.lock_count)
  end

  def test_lock_recursive
    lf = Xxeo::LockFile.new(@tmp_name1)
    assert(lf)

    5.times do |i|
      lf.lock
      assert(lf.locked?)
      assert_equal(i + 1, lf.lock_count)
    end

    4.times do |i|
      lf.unlock
      assert(lf.locked?)
      assert_equal(4 - i, lf.lock_count)
    end

    # Final unlock
    lf.unlock

    assert(!lf.locked?)
    assert_equal(0, lf.lock_count)
  end

  def test_unlock_fail
    lf = Xxeo::LockFile.new(@tmp_name1)
    assert(lf)

    lf.lock
    lf.unlock
    assert_raise RuntimeError do
      lf.unlock
    end


    lf = Xxeo::LockFile.new(@tmp_name1)
    assert(lf)

    assert_raise RuntimeError do
      lf.unlock
    end
  end

  # Have two processes fork, we need to test
  # that they do something orderly that they normally
  # wouldn't do if there wasn't a lock or if the lock
  # didn't work
  # For example, if the lock didn't work and they
  # did writes, they should end up all mixed up
  # This testing is hard since we cannot guaranty the
  # ordering of which process wins the lock.
  #
  def test_lock_with_processes
    5.times do | i |
      fork {
        File.open(@tmp_name2, "a") do
          | f |
          lf = Xxeo::LockFile.new(@tmp_name1)
          assert(lf)
          lf.lock
          10.times {
            f.syswrite(i.to_s)
            sleep 0.01
          }
          f.syswrite("\n")
          lf.unlock
        end
      }
    end
    l = Process.waitall
    l.each { |pid, pstat| assert_equal(0, pstat.exitstatus) }

    # Check the output
    f = File.new(@tmp_name2)
    lines = f.readlines
    f.close

    assert_equal(5, lines.length)
    lines.sort!
    5.times do | i |
      assert_equal((i.to_s * 10) + "\n", lines[i])
    end

  end

end

