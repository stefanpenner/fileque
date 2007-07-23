require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the fileq gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the fileq gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'fileq'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


STATS_DIRECTORIES = [ ['Code', 'lib/'], ['Unit tests', 'test/'] ]
desc "Report code statistics (KLOCs, etc) from the application"
task :stats do
  require 'code_statistics'
  CodeStatistics.new(*STATS_DIRECTORIES).to_s
end

spec = Gem::Specification.new do |s| 
  s.name = "fileq"
  s.version = "0.1.2"
  s.author = "Dru Nelson"
  s.email = "drudru@gmail.com"
  s.homepage = "http://code.google.com/p/fileque/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Simple transactional, persistent queue on top of Unix filesystem semantics"
  s.files = FileList["{bin,test,lib}/**/*"].to_a
  s.require_path = "lib"
  s.autorequire = "fileq"
  s.test_files = FileList["{test}/**/*.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
end

desc 'Generate fileq gem.'
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 

