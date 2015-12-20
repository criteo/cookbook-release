require_relative 'cookbook-release/commit'
require_relative 'cookbook-release/git-utilities'
require_relative 'cookbook-release/release'

require 'rake'
require 'rake/tasklib'

module CookbookRelease
  module Rake
    class CookbookTask < ::Rake::TaskLib

      def initialize(namespaced=false)
        define_tasks(namespaced)
      end

      def define_tasks(namespaced)

        desc "Prepare cookbook release and push tag to git"
        task "release!" do
          opts = {
            no_prompt: ENV['NO_PROMPT']
          }
          git = GitUtilities.new
          Release.new(git).release!
        end

        desc "Suggest new release version"
        task "release:suggest_version" do
          git = GitUtilities.new
          release = Release.new(git)
          release.display_suggested_version(*release.new_version)
        end

        desc "Display last released version"
        task "release:version" do
          git = GitUtilities.new
          release = Release.new(git)
          puts release.last_release
        end

        desc "Display changelog since last release"
        task "release:changelog" do
          git = GitUtilities.new
          release = Release.new(git)
          release.display_changelog(release.new_version.first)
        end
      end
    end
  end
end
