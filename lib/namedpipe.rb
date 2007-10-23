# NamedPipe 
#
# This is an abstraction over the named pipe API that is present in
# Unix.
#
# This API provides both sides of a pipe: a server and client api.
# The server API provides a blocking method.
#
#

require 'fcntl'

# 
# NamedPipe is a wrapper around the named pipe IPC 
# mechanism in Unix. Various unix's have differing
# ways of handling named pipes (permissions, error
# states, etc.)
#
# Essentially, it is a nice way for other processes
# to send a notification that some event occured
# with even the possibility of some data in that 
# message. (In contrast to signals). 
# 
# This package has a blocking listener method that can
# also return after a timeout.
#
# The file must exist with the desired permissions
# prior to creating the server
#

module Xxeo

  class NamedPipe

    def NamedPipe.create_server(pathname, options = {})
      options[:server]      = true
      options[:create]      ||= true
      options[:private]     ||= false # perms on pipe world writable
      np = NamedPipe.new(pathname, options)
      return np
    end

    def NamedPipe.create_client(pathname, options = {})
      options[:server]      = false
      options[:create]      = false
      options[:open_wait_secs]   = 1
      np = NamedPipe.new(pathname, options)
      return np
    end

    def send_mesg(msg)
      written = 0
      #deal with partial writes
      loop do
        len = @fd.syswrite(msg[written..-1])
        written += len
        return msg.length if written == msg.length
      end
    end

    def wait_on_data(timeout)
      res = Kernel.select([@fd], nil, nil, timeout)
      return res if res == nil

      data = ''

      loop do
        buf = @fd.sysread(4096)
        data += buf
        break if buf.length != 4096
      end

      return data
    end

    def close
      @fd.close
    end


private
    def initialize(pathname, options = {})
      
      @path = pathname
      @fd = nil
      @log = nil

      if (options[:verbose])
        @log = true
      end

      if (options[:server])
        @is_server = true
        create_pipe_if_necessary() if options[:create] != 'no'
        raise RuntimeError unless check_pipe()
        open_server()
      else
        @is_server = false
        @open_wait_secs = options[:open_wait_secs]
        raise RuntimeError unless check_pipe()
        open_client()
      end
    end

    def create_pipe_if_necessary
      return true if check_pipe()

      File.unlink(@path) if File.exist?(@path)
      res = system("mkfifo #{@path}")

      raise RuntimeError unless res
    end

    def open_server
      fd  = IO.sysopen(@path, Fcntl::O_RDONLY | Fcntl::O_NONBLOCK )
      @fd = IO.open(fd)
    end

    def open_client
      start = Time.now
      begin
        fd  = IO.sysopen(@path, Fcntl::O_WRONLY | Fcntl::O_NONBLOCK )
        @fd = IO.open(fd)
      rescue Errno::ENXIO
        if (Time.now - start) > @open_wait_secs
          raise
        else
          sleep 0.010
          retry
        end
      end
    end

    def check_pipe
      if not File.exist?(@path)
        log("File #{@path} does not exist")
        return false
      end
      if not File.pipe?(@path)
        log("File #{@path} is not a pipe")
        return false
      end
      if not File.readable?(@path)
        log("File #{@path} is not readable")
        return false
      end
      if not File.writable?(@path)
        log("File #{@path} is not writable")
        return false
      end
      return true
    end

    def log(msg)
      return unless @log
      print msg + "\n"
    end

  end

end

