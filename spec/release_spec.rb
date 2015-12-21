require_relative 'spec_helper'

describe Release do
  let(:git) { double('git') }

  levels = %w(major minor patch)
  levels.each do |l|
    send(:let, l.to_sym) do
      m = double(l)
      allow(m).to receive("#{l}?".to_sym).and_return true
      (levels - [l]).each do |ll|
        allow(m).to receive("#{ll}?".to_sym).and_return false
      end
      m
    end
  end

  describe '.new_version' do

    it 'raise when no commit has been made since last release' do
      allow(git).to receive(:compute_last_release).and_return('1.0.1'.to_version)
      expect(git).to receive(:compute_changelog).and_return([])

      release = Release.new(git)
      expect{release.new_version}.to raise_error(Release::ExistingRelease, /no commit since/i)
    end

    it 'suggests major release when one commit is major' do
      allow(git).to receive(:compute_last_release).and_return('1.0.1'.to_version)
      expect(git).to receive(:compute_changelog).and_return([minor, minor, major, patch])

      release = Release.new(git)
      new_version, reasons = release.new_version

      expect(new_version).to eq('2.0.0'.to_version)
    end

    it 'suggests minor release when one commit is minor' do
      allow(git).to receive(:compute_last_release).and_return('1.0.1'.to_version)
      expect(git).to receive(:compute_changelog).and_return([minor, minor, patch, patch])

      release = Release.new(git)
      new_version, reasons = release.new_version

      expect(new_version).to eq('1.1.0'.to_version)
    end

    it 'suggests patch release when all commits are patches' do
      allow(git).to receive(:compute_last_release).and_return('1.0.1'.to_version)
      expect(git).to receive(:compute_changelog).and_return([patch, patch, patch])

      release = Release.new(git)
      new_version, reasons = release.new_version

      expect(new_version).to eq('1.0.2'.to_version)
    end
  end

end
