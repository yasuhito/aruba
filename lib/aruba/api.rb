require 'tempfile'
require 'rbconfig'
require 'rubygems'
require 'shellwords'
require 'open4'

module Aruba
module Api
  def in_current_dir(&block)
    _mkdir(current_dir)
    Dir.chdir(current_dir, &block)
  end

  def current_dir
    File.join(*dirs)
  end

  def cd(dir)
    dirs << dir
    raise "#{current_dir} is not a directory." unless File.directory?(current_dir)
  end

  def dirs
    @dirs ||= ['tmp/aruba']
  end

  def create_file(file_name, file_content)
    in_current_dir do
      _mkdir(File.dirname(file_name))
      File.open(file_name, 'w') { |f| f << file_content }
    end
  end

  def append_to_file(file_name, file_content)
    in_current_dir do
      File.open(file_name, 'a') { |f| f << file_content }
    end
  end

  def create_dir(dir_name)
    in_current_dir do
      _mkdir(dir_name)
    end
  end

  def check_file_presence(paths, expect_presence)
    in_current_dir do
      paths.each do |path|
        if expect_presence
          File.should be_file(path)
        else
          File.should_not be_file(path)
        end
      end
    end
  end

  def check_file_content(file, partial_content, expect_match)
    regexp = compile_and_escape(partial_content)
    in_current_dir do
      content = IO.read(file)
      if expect_match
        content.should match(regexp)
      else
        content.should_not match(regexp)
      end
    end
  end

  def _mkdir(dir_name)
    FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)
  end

  def unescape(string)
    eval(%{"#{string}"})
  end

  def compile_and_escape(string)
    Regexp.compile(Regexp.escape(string))
  end

  def combined_output(name=nil)
    if(name)
      stdout = children[name].stdout
      stderr = children[name].stderr
    else
      stdout = @last_stdout
      stderr = @last_stderr
    end
    raise "Nothing has been run yet" if stdout.nil?
    stdout + (stderr == '' ? '' : "\n#{'-'*70}\n#{stderr}")
  end

  def use_rvm(rvm_ruby_version)
    if File.exist?('config/aruba-rvm.yml')
      @rvm_ruby_version = YAML.load_file('config/aruba-rvm.yml')[rvm_ruby_version] || rvm_ruby_version
    else
      @rvm_ruby_version = rvm_ruby_version
    end
  end

  def use_rvm_gemset(rvm_gemset)
    @rvm_gemset = rvm_gemset
  end

  def run(cmd, name=nil)
    cmd = detect_ruby_script(cmd)
    cmd = detect_ruby(cmd)

    announce("$ #{cmd}") if @announce_cmd

    in_current_dir do
      mode = RUBY_VERSION =~ /^1\.9/ ? {:external_encoding=>"UTF-8"} : 'r'

      if(name)
        pid, stdin, stdout, stderr = Open4::popen4(*Shellwords.shellwords(cmd))
        children[name] = Child.new(pid, stdin, stdout, stderr)
      else
        Open4::popen4(*Shellwords.shellwords(cmd)) do |pid, stdin, stdout, stderr|
          @last_stdout = stdout.read
          announce(@last_stdout) if @announce_stdout

          @last_stderr = stderr.read
          announce(@last_stderr) if @announce_stderr
        end
        @last_exit_status = $?.exitstatus
      end
    end
  end

  def last_exit_status
    @last_exit_status
  end

  def child_write(input, name)
    children[name].write(input)
  end

  def child_running?(name)
    children[name].running?
  end

  def child_exit_status(name)
    children[name].exit_status
  end

  def child_sig(signal, name)
    children[name].kill(signal)
  end

  def children
    @children ||= {}
  end

  def kill_all
    children.each do |name, child|
      child.kill('TERM')
    end
  end

  def detect_ruby(cmd)
    if cmd =~ /^ruby\s/
      cmd.gsub(/^ruby\s/, "#{current_ruby} ")
    else
      cmd
    end
  end

  COMMON_RUBY_SCRIPTS = /^(?:bundle|cucumber|gem|jeweler|rails|rake|rspec|spec)\s/

  def detect_ruby_script(cmd)
    if cmd =~ COMMON_RUBY_SCRIPTS
      "ruby -S #{cmd}"
    else
      cmd
    end
  end

  def current_ruby
    if @rvm_ruby_version
      rvm_ruby_version_with_gemset = @rvm_gemset ? "#{@rvm_ruby_version}%#{@rvm_gemset}" : @rvm_ruby_version
      "rvm #{rvm_ruby_version_with_gemset} ruby"
    else
      File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
    end
  end

  class Child
    def initialize(pid, stdin, stdout, stderr)
      @pid, @stdin, @stdout, @stderr = pid, stdin, stdout, stderr
    end

    def write(input)
      @stdin.write(input)
    end

    def stdout
      @stdout.read
    end

    def stderr
      @stderr.read
    end

    def running?
      begin
        Process.getpgid(@pid)
      rescue Errno::ESRCH
        false
      end
    end

    def exit_status
      ignored, status = Process::waitpid2(@pid)
      status.exitstatus
    end

    def kill(signal)
      Process.kill(Signal.list[signal], @pid)
    end
  end
end
end
