# FileQ

require 'yaml'
#require 'fcntl'

module Xxeo

  class WrongStatus < StandardError; end

  class Job

    def Job.create(queue, name, path, status)
      raise unless queue.class == Xxeo::FileQ

      Job.new(queue, name, path, status)
    end

    def name
      return @name
    end

    def data
      raise WrongStatus.new('cannot disown a non-owned job') unless @own
      data = nil
      File.open(@path + '/data') { |f| data = f.read }
      return data
    end

    def owning_pid
      @owning_pid 
    end

    def is_file?
      meta = read_meta
      raise unless meta
      return meta[:XX_type] == 'file'
    end

    def original_pathname
      meta = read_meta
      raise unless meta
      return meta[:XX_original_file_name] if meta[:XX_type] == 'file'
      return nil
    end

    def read_meta
      return @fq.meta_for_job(@name)
    end

    def own?
      @own
    end

    def disown
      raise WrongStatus.new('cannot disown a non-owned job') unless @own
      @own = false
      File.unlink(@path + '/pid')
      @owning_pid = nil
    end

    def set_status(path, status)
      @path = path
      @status = status
    end

    def pull
      return self if @own 

      # This is kinda wonky, obviously
      # since the @fq already called set_as_active on an object
      if @fq.pull_job(@name)
        @own = true
        @path = @fq.run_que_path + @name
        @status = ST_RUN
        @owning_pid = $$
        return self
      end
      return nil
    end

    def set_as_active
      @own = true
      # Record
      @path = @fq.run_que_path + @name
      @status = ST_RUN
      File.open(@path + '/pid', "w") { |f| f.write("#{$$}\n") }
      @owning_pid = $$
    end

    # TODO: this could be stale
    def status
      return @status if @own
      return @fq.status(@name)
    end

    # TODO: this could be stale
    def status_mesg
      return @status_mesg if @own
      return @fq.status_mesg_for_job(@name)
    end

    # The @fq locks and then does a callback here
    def callback_status_mesg
      data = ''
      File.open(@path + '/status', "r") do
        |f|
        data = f.read
      end
      return data
    end

    def status_mesg=(msg)
      raise WrongStatus.new('cannot set status mesg on non-owned job') unless @own
      @status_mesg = msg
      File.open(@path + '/status', "w") { |f| f.write(msg) }
    end

    def status_all
      return [@status, @owning_pid, status_mesg]
    end

    def log(msg)
      raise WrongStatus.new('cannot log on non-owned job') unless @own
      File.open(@path + '/log', "a") do
        |f|
        log_msg = Time.now.to_s + " == " + msg + "\n"
        f.write(log_msg)
        @logs << log_msg
      end
    end

    def read_log
      return @logs.join('') if @own
      return @fq.status_logs_for_job(@name)
    end

    # The @fq locks and then does a callback here
    def callback_read_logs
      data = ''
      File.open(@path + '/log', "r") do
        |f|
        data = f.read
      end
      return data
    end

    def mark_done
      raise WrongStatus.new('cannot log on non-owned job') unless @own
      status_mesg = "finishing"
      @fq.mark_job_done(self)
    end

    def mark_error
      raise WrongStatus.new('cannot log on non-owned job') unless @own
      status_mesg = "finishing"
      @fq.mark_job_error(self)
    end

    private

    def initialize(queue, name, path, status)
      @fq = queue
      @name = name
      @path = path
      @own = false
      @owning_pid = nil
      @status = status
      @status_mesg = ''
      @logs = []
    end

  end

end

