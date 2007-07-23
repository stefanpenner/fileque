# FileQ 
#
# This is a class which manages an on-disk/persistent, ordered, queue.
# You can insert data or files into the queue.
#
#   In Process A (for example a mongrel)
#   fq = FileQ.initialize('/path/to/que')
#   fq.insert_file('/path/to/file')
#   <watching process or fork/exec worker process>
#
#   In Process B (worker process)
#   fq = FileQ.initialize('/path/to/que')
#   job = fq.pull_job(job_id if provided, or nil for oldest job)
#   <memory/cpu intense work>
#   job.mark_as_done
#

require 'yaml'
require 'fcntl'
require 'job'
require 'lockfile'

module Xxeo

  ST_QUEUED   = :ST_QUEUED
  ST_RUN      = :ST_RUN
  ST_DONE     = :ST_DONE
  ST_PAUSED   = :ST_PAUSED
  ST_ERROR    = :ST_ERROR
  ST_UNKNOWN  = :ST_UNKNOWN

  class FileQ

    @@config_path = nil
    @@config = nil
    @@dir = nil
    @@fname_rgx = /(\d+.\d\d\d):(\d+):(\d+)\.fq/ 

    def initialize(name, options = {})
      options[:env]      ||= 'development'
      @err = '' 
      
      if not @dir
        if options[:dir]
          @dir = options[:dir]
        elsif 
          @@config_path = options[:config_path] || ('./config/fileq.yml')
          @@config = YAML.load_file(@@config_path)
          # USe 
          path = @@config[name][options[:env]]['pathname']

          # TODO
          # If it is an expression, evaluate the env var
          @dir = path
        else
          return nil
        end
      end

      @lock = nil

    end

    def last_error
      return @err
    end

    # Names will be in format of
    # YYYYMMDD.HHMM.SS
    
    def generate_name
      z = Time.now.getutc
      name = z.strftime("%Y%m%d.%H%M.%S.") + sprintf("%03d", (z.tv_usec / 1000))
      return name
      # Process.pid kddkd
    end

    def log(msg)
      @err = msg
      File.open(@dir + '/_log', "a") do
        |f|
        f.write(Time.now.to_s + " == " + msg + "\n")
      end
    end

    def read_log
      data = ''
      File.open(@dir + '/_log', "r") do
        |f|
        data = f.read
      end
      return data
    end

    def insert_file(fname, opts = {})
      unless FileTest.writable?(fname)
        log("Supplied file: #{fname} is not writable. Failed ot insert. (see log)")
        return nil
      end
      opts[:XX_type] = 'file'
      opts[:XX_data] = fname
      insert(opts)
    end

    def insert_data(data, opts = {})
      opts[:XX_type] = 'data'
      opts[:XX_data] = data
      insert(opts)
    end

    def length
      Dir.glob(@dir + '/que/*').length
    end

    def all_lengths
      a = %w(_tmp que run pause done _err)
      h = Hash.new(0)
      a.map { 
        |e|
        a = Dir.glob(@dir + "/#{e}/*")
        l = a.length
        h[e.to_sym] = l if l > 0
      }
      return h
    end

    def internal_job_exists?(q_name, job_name)
      throw ArgumentError unless ['que', 'run', 'done', 'pause', '_err'].include?(q_name)
      throw ArgumentError unless job_name
      result = nil
      path = @dir + '/' + q_name + '/' + job_name
      return FileTest.directory?(path)
    end

    def status(job_name = nil)
      throw ArgumentError unless job_name
      lock
      result = ST_UNKNOWN
      [['que', ST_QUEUED], ['run', ST_RUN], ['done', ST_DONE], ['pause', ST_PAUSED], ['_err', ST_ERROR]].map {
        | dir |
        path = @dir + '/' + dir[0] + '/' + job_name
        if FileTest.directory? path
          result = dir[1]
          break
        end
      }
      unlock
      return result
    end

    def meta_for_job(job_name)
      lock
      data = nil
      [['que', ST_QUEUED], ['run', ST_RUN], ['done', ST_DONE], ['pause', ST_PAUSED], ['_err', ST_ERROR]].map {
        | dir |
        path = @dir + '/' + dir[0] + '/' + job_name
        if FileTest.directory? path
          data = YAML.load_file(path + '/meta.yml')
          break
        end
      }
      unlock
      return data
    end

    def status_mesg_for_job(job_name)
      lock
      data = ''
      [['que', ST_QUEUED], ['run', ST_RUN], ['done', ST_DONE], ['pause', ST_PAUSED], ['_err', ST_ERROR]].map {
        | dir |
        path = @dir + '/' + dir[0] + '/' + job_name
        if FileTest.directory? path
          if FileTest.readable? path + '/status'
            File.open(path + '/status') { |f| data = f.read }
          end
          break
        end
      }
      unlock
      return data
    end

    def internal_find_job(job_name = nil)
      result = [nil, nil]
      if job_name
        [['que', ST_QUEUED], ['run', ST_RUN], ['done', ST_DONE], ['pause', ST_PAUSED], ['_err', ST_ERROR]].map {
          | dir |
          path = @dir + '/' + dir[0] + '/' + job_name
          if FileTest.directory? path
            result = [Job.create(self, job_name, path, dir[1]), dir[1]]
            break
          end
        }
      else
        # Find the oldest job in the queue
        jobs = Dir.glob(que_path + '*')
        min = jobs.min
        if min
          name = File.basename(min)
          result = [Job.create(self, name, que_path + name, ST_QUEUED), ST_QUEUED]
        end
      end
      return result
    end

    def find_job(job_name = nil)
      lock
      job,status = internal_find_job(job_name)
      unlock
      return job
    end

    # Currently we can only move items from the que to the run queu
    # TODO: allow paused or error jobs to be reset, (maybe even done jobs)
    # definitely log history in those jobs
    def pull_job(job_name = nil)
      lock
      job,status = internal_find_job(job_name)
      if job && status == ST_QUEUED
        # Move to run, notice use of job.name rather than job_name
        # .. if we are pulling a new job, it could be nil
        FileUtils.mv(@dir + '/que/' + job.name, @dir + '/run/' + job.name)
        job.set_as_active
      elsif job
        # We cannot pull a job that isn't queued
        log("cannot pull job that isn't queued: " + job_name)
        job = nil
      end
      unlock
      return job
    end

    def mark_job_done(job = nil)
      throw ArgumentError unless job
      throw ArgumentError unless job.own?
      lock
      if internal_job_exists?('run', job.name)
        # Move to run
        job.disown
        FileUtils.mv(@dir + '/run/' + job.name, @dir + '/done/' + job.name)
        job.set_status(@dir + '/done/' + job.name, ST_DONE)
      else
        log('attemped to mark invalid job as done: ' + job.name)
        job = nil
      end
      unlock
      return job
    end

    def mark_job_error(job = nil)
      throw ArgumentError unless job
      throw ArgumentError unless job.own?
      lock
      if internal_job_exists?('run', job.name)
        # Move to run
        job.disown
        FileUtils.mv(@dir + '/run/' + job.name, @dir + '/_err/' + job.name)
        job.set_status(@dir + '/_err/' + job.name, ST_ERROR)
      else
        log('attemped to mark invalid job as error: ' + job.name)
        job = nil
      end
      unlock
      return job
    end

    def files_for_store
      d = [
        ['', 'd'],
        ['_lock', 'w'],
        ['_log', 'w'],
        ['_tmp', 'd'],
        ['que', 'd'],
        ['run', 'd'],
        ['pause', 'd'],
        ['done', 'd'],
        ['_err', 'd'],
      ]
      return d
    end

    def que_path
      return @dir + '/que/'
    end

    def run_que_path
      return @dir + '/run/'
    end

    def done_que_path
      return @dir + '/done/'
    end

    def error_que_path
      return @dir + '/_err/'
    end

    def pause_que_path
      return @dir + '/pause/'
    end

    def create_queue_dirs
      files_for_store.map {
        | e |
        FileUtils.mkdir(@dir + '/' + e[0]) if e[1] == 'd'
        FileUtils.touch(@dir + '/' + e[0]) if e[1] == 'w'
      }
    end

    def verify_store

      files_for_store.map {
        | e |
        if e[1] == 'w'
          unless FileTest.exists?( @dir + '/' + e[0])
            log "bad queue dir: file '#{e[0]}' does not exist"
            return false
          end
          unless FileTest.writable?( @dir + '/' + e[0])
            log "bad queue dir: file '#{e[0]}' not writable"
            return false
          end
        elsif e[1] == 'd'
          unless FileTest.directory?( @dir + '/' + e[0])
            log "bad queue dir: '#{e[0]}' not a directory"
            return false
          end
        else
          log "Bad code in verify store"
          return false
        end
      }

      @err = ''
      return true

    end


    private

    def lock
      @lock = LockFile.new(@dir + '/_lock') if not @lock

      @lock.lock
    end

    def unlock
      @lock.unlock
    end

    def insert(opts = {})
      unless opts[:XX_type] && opts[:XX_data]
        log("Invalid call to insert. Missing arguments (see log)")
        return nil
      end

      name = tmpName = ''

      lock

      begin
        # Flaw - what if somebody screwed up and their
        # are files there from the future
        # TODO: handle that case
        # We should always succeed if there is room!
        1000.times do 
          |i|
          n = generate_name

          tmpName = @dir + '/_tmp/' + n

          if i > 5
            log("Queue insertion problem: too many collisions")
          elsif i > 990
            log("Queue insertion problem: too many collisions")
            unlock
            return nil
          end


          if FileTest.exists?(tmpName)
            sleep 0.001
            next
          end

          # We have our name
          FileUtils.mkdir(tmpName)
          # Do addtional TODO tests for writability
          # and lack of pre-existing files
          
          unlock

          name = n

          break
        end

      rescue
        log($!)
        unlock
        return false
      end

      opts[:XX_status] = 'inserted'

      if opts[:XX_type] == 'file'
        fname = opts[:XX_data]
        opts[:XX_original_file_name] = fname
        # Move file to new dir
        FileUtils.mv(fname, @dir + '/_tmp/' + name + '/data')
      else
        File.open(@dir + '/_tmp/' + name + '/data', "w") { |f| f.write(opts[:XX_data]) }
      end

      # Write meta file 
      File.open(@dir + '/_tmp/' + name + '/meta.yml', "w") do
        | out |
        YAML.dump(opts, out)
      end

      # Move job to '/que' directory
      FileUtils.mv(@dir + '/_tmp/' + name, @dir + '/que/' + name)

      job = Job.create(self, name, @dir + '/que/' + name, ST_QUEUED)
      return job
    end

  end

end
