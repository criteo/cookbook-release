require_relative 'spec_helper'

describe CookbookRelease::Changelog do
  let(:git) do
    double('git', :no_prompt= => true)
  end

  describe '.html' do

    it 'colorize Risky commits in red' do
      expect(git).to receive(:compute_changelog).and_return([
        CookbookRelease::Commit.new(hash: '654321', subject: '[Risky] hello', author: 'John Doe'),
        CookbookRelease::Commit.new(hash: '123456', subject: 'hello', author: 'John Doe'),
      ])
      changelog = CookbookRelease::Changelog.new(git)
      expect(changelog.html).to match(/color=red((?!color=grey).)*Risky/m)
    end
  end

end
