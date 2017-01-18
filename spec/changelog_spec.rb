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
    it 'expand body' do
      expect(git).to receive(:compute_changelog).and_return(
        [
          CookbookRelease::Commit.new(
            hash: '654321',
            subject: '[Risky] hello',
            author: 'John Doe',
            email: 'j.doe@nobody.com',
            body: 'Some Men Just Want to Watch the World Burn')
        ]
      )
      changelog = CookbookRelease::Changelog.new(git, expand_risky: true)
      expect(changelog.markdown).to include("\n```\nSome Men Just Want")
    end
  end
end
