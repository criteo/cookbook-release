require_relative 'spec_helper'

describe Commit do

  let(:breaking_change) { Commit.new(subject: '[Breaking] Removed thing') }
  let(:fix_change) { Commit.new(subject: 'This is a fix') }
  let(:minor_change) { Commit.new(subject: 'This introduces a feature') }

  describe '.(major|patch|minor)?' do
    it 'detects major changes' do
      expect(breaking_change).to     be_major
      expect(fix_change)     .not_to be_major
      expect(minor_change)   .not_to be_major
    end
    it 'detects minor changes' do
      expect(breaking_change).not_to be_minor
      expect(fix_change)     .not_to be_minor
      expect(minor_change)   .to     be_minor
    end
    it 'detects patch changes' do
      expect(breaking_change).not_to be_patch
      expect(fix_change)     .to     be_patch
      expect(minor_change)   .not_to be_patch
    end
  end
end
