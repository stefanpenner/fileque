# LockFile` 
#
# This assumes that a single threaded process is using
# this object to use a file on disk as a lock/mutex
# for synchronization.
#
#   class User < ActiveRecord::Base
#     acts_as_audited
#   end
#
# See <tt>CollectiveIdea::Acts::Audited::ClassMethods#acts_as_audited</tt>
# for configuration options
#http://rails.techno-weenie.net/tip/2005/11/19/validate_your_forms_with_a_table_less_model
#http://lists.vanruby.com/pipermail/discuss/2006-January/000050.html

# class Order < InActiveRecord
# column :id,            :integer
# column :name,       :string
# column :address,    :string
#  ...
#  validates_presence_of :name, :address ....
#
#

require 'fcntl'

module Xxeo

  class LockFile

    def initialize(pathname, options = {})
      options[:env]      ||= 'development'
      
      raise "lockfile not writable" if not File.writable? pathname

      @f = File.open(pathname, 'r')

      raise "could not open file" if not @f

      @lock_count = 0
    end

    # We allow a process that holds a lock to recursively
    # acquire the lock, the allows the higher level programs
    # to not have to keep track of the lock status
    # This is becase the flock mechanism doesn't do reference
    # counting.
    
    def lock
      # already locked, just increase the ref count
      if @lock_count > 0
        @lock_count += 1
        return
      end

      # THIS COULD BLOCK
      @f.flock(File::LOCK_EX)
      @lock_count = 1
    end

    def unlock
      if @lock_count > 1
        @lock_count -= 1
        return
      end

      if @lock_count == 1
        @f.flock(File::LOCK_UN)
        @lock_count -= 1
        return
      end

      if @lock_count < 1
        raise "Attempt to unlock an unlocked LockFile"
      end
    end

    def locked?
      return @lock_count > 0
    end

    def lock_count
      return @lock_count
    end

  end

end
