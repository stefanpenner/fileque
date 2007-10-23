# =============================================================================
# A set of rake tasks for the fileq system under rails
# =============================================================================
#
# This file is mean to be used in the lib/tasks/ directory
# of a rails project

Dir["#{RAILS_ROOT}/vendor/gems/fileq-*"].each do |dir|
        lib = "#{dir}/lib"
        next unless File.directory?(lib)
        $LOAD_PATH.unshift << lib unless $LOAD_PATH.include?(lib)
end

require 'fileq'

namespace :fileq do

  desc "Sets up the queue directory files. Safe to run on existing que."
  task(:setup) do 
    fq = Xxeo::FileQ.new('abook')
    fq.create_queue_dirs
    fq.verify_store
  end

  desc "Test."
  task(:test) do 
    p RAILS_ROOT
    p $LOAD_PATH
  end

end

