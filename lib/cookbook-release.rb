require_relative 'cookbook-release/commit'
require_relative 'cookbook-release/git-utilities'
require_relative 'cookbook-release/supermarket'
require_relative 'cookbook-release/release'
require_relative 'cookbook-release/changelog'

require 'rake'
require 'rake/tasklib'

module CookbookRelease
  module Rake

    class RepoTask < ::Rake::TaskLib
      def initialize(opts = {}, &html_block)
        desc 'Display raw changelog between branches'
        task 'changelog:raw', [:sub_dir] do |_, args|
          git = GitUtilities.new('sub_dir': args['sub_dir'])
          puts Changelog.new(git, opts).raw
        end

        desc 'Display raw changelog between branches with risky commits on top'
        task 'changelog:raw_priority', [:sub_dir] do |_, args|
          git = GitUtilities.new(args)
          git = GitUtilities.new('sub_dir': args['sub_dir'])
          puts Changelog.new(git, opts).raw_priority
        end

        desc 'Display html changelog between branches'
        task 'changelog:html', [:sub_dir] do |_, args|
          git = GitUtilities.new('sub_dir': args['sub_dir'])
          html = Changelog.new(git, opts).html
          if block_given?
            html = html_block.call(html)
          end
          puts html
        end

        desc 'Display html changelog between branches with risky commits on top'
        task 'changelog:html_priority', [:sub_dir] do |_, args|
          git = GitUtilities.new('sub_dir': args['sub_dir'])
          html = Changelog.new(git, opts).html_priority
          if block_given?
            html = html_block.call(html)
          end
          puts html
        end

        desc 'Display markdown changelog between branches'
        task 'changelog:markdown', [:sub_dir] do |_, args|
          git = GitUtilities.new('sub_dir': args['sub_dir'])
          puts Changelog.new(git, opts).markdown
        end

        desc 'Display markdown changelog between branches with risky commits on top'
        task 'changelog:markdown_priority', [:sub_dir] do |_, args|
          git = GitUtilities.new('sub_dir': args['sub_dir'])
          puts Changelog.new(git, opts).markdown_priority
        end
      end
    end

    class CookbookTask < ::Rake::TaskLib

      def initialize(namespaced=false)
        define_tasks(namespaced)
      end

      def define_tasks(namespaced)

        desc 'Prepare cookbook release and push tag to git'
        task 'release!' do
          opts = {
            no_prompt: ENV['NO_PROMPT'],
            category: ENV['COOKBOOK_CATEGORY'],
          }
          git = GitUtilities.new
          Release.new(git, opts).release!
        end

        desc 'Suggest new release version'
        task 'release:suggest_version' do
          git = GitUtilities.new
          release = Release.new(git)
          release.display_suggested_version(*release.new_version)
        end

        desc 'Display last released version'
        task 'release:version' do
          git = GitUtilities.new
          release = Release.new(git)
          puts release.last_release
        end

        desc 'Display changelog since last release'
        task 'release:changelog' do
          git = GitUtilities.new
          release = Release.new(git)
          release.display_changelog(release.new_version.first)
        end
      end
    end
  end
end
