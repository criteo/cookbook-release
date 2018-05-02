require_relative 'spec_helper'

describe CookbookRelease::Changelog do
  let(:git) do
    double('git', :no_prompt= => true)
  end

  describe '.html' do

    it 'colorize Risky commits in red' do
      expect(git).to receive(:compute_changelog).and_return([
        CookbookRelease::Commit.new(hash: '654321', subject: '[Risky] hello', author: 'John Doe', email: 'j.doe@nobody.com'),
        CookbookRelease::Commit.new(hash: '123456', subject: 'hello', author: 'John Doe', email: 'j.doe@nobody.com'),
      ])
      changelog = CookbookRelease::Changelog.new(git)
      expect(changelog.html).to match(/color=red((?!color=grey).)*Risky/m)
    end
  end

  describe '.md' do
    it 'add formatting' do
      expect(git).to receive(:compute_changelog).and_return(
        [
          CookbookRelease::Commit.new(
            hash: '123456',
            subject: 'hello',
            author: 'John Doe',
            email: 'j.doe@nobody.com')
        ]
      )
      changelog = CookbookRelease::Changelog.new(git)
      expect(changelog.markdown).to eq('*123456* _John Doe <j.doe@nobody.com>_ `hello`')
    end
    context 'risky commit' do
      let(:commit) do
        [
          CookbookRelease::Commit.new(
            hash: '654321',
            subject: '[Risky] hello',
            author: 'John Doe',
            email: 'j.doe@nobody.com',
            body: 'Some Men Just Want to Watch the World Burn')
        ]
      end

      it 'expands the body' do
        expect(git).to receive(:compute_changelog).and_return(commit)
        changelog = CookbookRelease::Changelog.new(git, expand_risky: true)
        expect(changelog.markdown).to include("\n```\nSome Men Just Want")
      end

      it 'mentions the author' do
        expect(git).to receive(:compute_changelog).and_return(commit)
        changelog = CookbookRelease::Changelog.new(git, expand_risky: true)
        expect(changelog.markdown).to start_with('*654321* @j.doe `[Risky] hello`')
      end
    end
    context 'Separates risky and non-risky+non-nodes' do
      let(:commits) do
        [
          CookbookRelease::Commit.new(
            hash: '654321',
            subject: 'hello',
            author: 'John Doe',
            email: 'j.doe@nobody.com',
            body: 'New Men Just Want to Watch the World Burn',
            nodes_only: false),
          CookbookRelease::Commit.new(
            hash: '654321',
            subject: '[Risky] hello',
            author: 'John Doe',
            email: 'j.doe@nobody.com',
            body: 'Some Men Just Want to Watch the World Turn',
            nodes_only: true),
          CookbookRelease::Commit.new(
            hash: '654321',
            subject: 'hello only nodes',
            author: 'John Doe',
            email: 'j.doe@nobody.com',
            body: 'Old Men Just Want to Watch the World Learn',
            nodes_only: true)
        ]
      end

      it 'expands the body with non-risky+non-nodes' do
        expect(git).to receive(:compute_changelog).and_return(commits)
        changelog = CookbookRelease::Changelog.new(git, expand_risky: true, nodes_only: true)
        expect(changelog.markdown_priority_nodes.join('')).to include(
          "\n*Non-risky/major, Non-node-only commits*\n*654321* _John Doe <j.doe@nobody.com>_ `hello`\n*Full"
        )
      end
    end
  end
end
