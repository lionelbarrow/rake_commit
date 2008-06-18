require 'readline'
require 'open-uri'
require 'rexml/document'
require 'tmpdir'

require File.expand_path(File.dirname(__FILE__) + '/commit_message')
require File.expand_path(File.dirname(__FILE__) + '/cruise_status')

desc "Run before checking in"
task :pc => ['svn:add', 'svn:delete', 'svn:up', :default, 'svn:st']

desc "Run to check in"
task :commit => [:pc, :ci]

desc "Check in code, prompting for metadata"
task :ci do
  if files_to_check_in? && ok_to_check_in?
    puts %x[svn st --ignore-externals]
    command = %[svn ci -m "#{CommitMessage.prompt.to_s}"]
    puts command
    puts %x[#{command}]
  end
end

def files_to_check_in?
  %x[svn st --ignore-externals].split("\n").reject {|line| line[0,1] == "X"}.any?
end

def ok_to_check_in?
  return true unless self.class.const_defined?(:CCRB_RSS)
  cruise_status = CruiseStatus.new(CCRB_RSS)
  cruise_status.pass? ? true : are_you_sure?( "Build FAILURES: #{cruise_status.failures.join(', ')}" )
end

def are_you_sure?(message)
  puts "\n", message
  input = ""
  while (input.strip.empty?)
    input = Readline.readline("Are you sure you want to check in? (y/n): ")
  end
  return input.strip.downcase[0,1] == "y"
end