require_relative 'cookbook-release/commit'
require_relative 'cookbook-release/git-utilities'
require_relative 'cookbook-release/release'

require 'rake'
require 'rake/tasklib'

module CookbookRelease
  module Rake
    class CookbookTask < ::Rake::TaskLib

      def initialize
        define_tasks
      end

      def define_tasks
        desc "Prepare cookbook release and push tag to git"
        task "cookbook:release" do
          git = GitUtilities.new
          Release.new(git).release!
        end

        desc "Suggest new release version"
        task "cookbook:suggest-release" do
          git = GitUtilities.new
          release = Release.new(git)
          release.display_suggested_version(*release.new_version)
        end

        desc "Display last released version"
        task "cookbook:suggest-release" do
          git = GitUtilities.new
          release = Release.new(git)
          release.last_release
        end

        desc "Display changelog"
        task "cookbook:changelog" do
          git = GitUtilities.new
          release = Release.new(git)
          release.display_changelog(release.new_version.first)
        end
      end
    end
  end
end
