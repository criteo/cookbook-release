require_relative 'spec_helper'

require 'mixlib/shellout'
require 'fileutils'

describe CookbookRelease::GitUtilities do
  before(:each) do
    @tmp = Dir.mktmpdir('cookbook-release')
    @old_dir = Dir.pwd
    Dir.chdir(@tmp)
    cmds = <<-EOH
    git init .
    git config user.email "you@example.com"
    git config user.name Hello
    git commit --allow-empty -m 'none'
    git tag 1.0.0
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

  let(:git) { CookbookRelease::GitUtilities.new }

  describe 'git directory' do
    it 'detects non-git' do
      tmp = Dir.mktmpdir('cookbook-release')
      expect(CookbookRelease::GitUtilities.git?(tmp)).to be(false)
      FileUtils.rm_rf(tmp)
    end

    it 'detects git' do
      tmp = Dir.mktmpdir('cookbook-release')
      cmd = Mixlib::ShellOut.new("git init #{tmp}")
      cmd.run_command
      cmd.error!
      expect(CookbookRelease::GitUtilities.git?(tmp)).to be(true)
      FileUtils.rm_rf(tmp)
    end
  end

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
      expect(changelog.size).to eq(3)
      expect(changelog.map {|c| c[:subject]}).to contain_exactly('A commit', 'Another commit', 'A third one')
    end

    it 'parse correctly commits' do
      cmds = <<-EOH
      git commit --allow-empty -m "subject" -m "body" -m "line2"
      git commit --allow-empty -m "without body"
      EOH
      cmds.split("\n").each do |cmd|
        cmd = Mixlib::ShellOut.new(cmd)
        cmd.run_command
        cmd.error!
      end

      changelog = git.compute_changelog('1.0.0')
      expect(changelog.size).to eq(2)
      expect(changelog[1][:subject]).to eq('subject')
      expect(changelog[1][:body].lines).to include("body\n")
      expect(changelog[0][:body]).to be_nil
    end

    it 'can use short sha' do
      cmd = Mixlib::ShellOut.new('git commit --allow-empty -m "subject"')
      cmd.run_command
      cmd.error!

      changelog = git.compute_changelog('HEAD~1', true)
      expect(changelog[0][:hash].size).to eq(7)
    end

    it 'can use long sha' do
      cmd = Mixlib::ShellOut.new('git commit --allow-empty -m "subject"')
      cmd.run_command
      cmd.error!

      changelog = git.compute_changelog('HEAD~1', false)
      expect(changelog[0][:hash].size).to eq(40)
    end
  end
end
