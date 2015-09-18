require_relative 'spec_helper'

require 'mixlib/shellout'
require 'fileutils'

describe GitUtilities do
  before(:each) do
    @tmp = Dir.mktmpdir('cookbook-release')
    @old_dir = Dir.pwd
    Dir.chdir(@tmp)
    cmds = <<-EOH
    git init .
    git config user.email "you@example.com"
    git config user.name Hello
    EOH
    cmds.split("\n").each do |cmd|
      cmd = Mixlib::ShellOut.new(cmd)
      cmd.run_command
      cmd.error!
    end
  end

  after(:each) do
    Dir.chdir(@old_dir)
    FileUtils.rm_rf(@tmp)
  end

  let(:git) { GitUtilities.new }

  describe '.clean_index(?|!)' do
    it 'detects clean index' do
      expect(git.clean_index?).to be(true)
      expect{git.clean_index!}.not_to raise_error
    end
    it 'detects dirty cached index' do
      cmds = <<-EOH
      touch toto
      git add toto
      EOH
      cmds.split("\n").each do |cmd|
        cmd = Mixlib::ShellOut.new(cmd)
        cmd.run_command
        cmd.error!
      end
      expect(git.clean_index?).to be(false)
      expect{git.clean_index!}.to raise_error(RuntimeError)
    end
    it 'detects dirty cached index' do
      cmds = <<-EOH
      touch toto
      git add toto
      git commit -m'none'
      echo titi > toto
      EOH
      cmds.split("\n").each do |cmd|
        cmd = Mixlib::ShellOut.new(cmd)
        cmd.run_command
        cmd.error!
      end
      expect(git.clean_index?).to be(false)
      expect{git.clean_index!}.to raise_error(RuntimeError)
    end
  end

  describe '.compute_last_release' do
    it 'finds the last release' do
      cmds = <<-EOH
      touch toto
      git add toto
      git commit -m'none'
      git tag 1.0.0
      git commit --allow-empty -m 'none'
      git tag 1.2.43
      git commit --allow-empty -m 'none'
      git tag v1.2.3
      git commit --allow-empty -m 'none'
      git tag interesting_tag
      EOH
      cmds.split("\n").each do |cmd|
        cmd = Mixlib::ShellOut.new(cmd)
        cmd.run_command
        cmd.error!
      end
      expect(git.compute_last_release).to eq("1.2.43")
    end
  end

  describe '.compute_changelog' do
    it 'find the proper changelog' do
      cmds = <<-EOH
      touch toto
      git add toto
      git commit -m'none'
      git tag 1.0.0
      git commit --allow-empty -m 'A commit'
      git commit --allow-empty -m 'Another commit'
      git commit --allow-empty -m 'A third one'
      EOH
      cmds.split("\n").each do |cmd|
        cmd = Mixlib::ShellOut.new(cmd)
        cmd.run_command
        cmd.error!
      end

      changelog = git.compute_changelog('1.0.0')
      expect(changelog.size).to be(3)
      expect(changelog.map {|c| c[:subject]}).to contain_exactly('A commit', 'Another commit', 'A third one')
    end
  end
end
