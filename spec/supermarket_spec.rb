require_relative 'spec_helper'

describe CookbookRelease::Supermarket do
  let (:opts) do
    { user_id: 'a_name', client_key_file: 'a_file',
      url: 'http://a_url' }
  end

  before(:each) do
    @tmp = Dir.mktmpdir('cookbook-release')
    @old_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  after(:each) do
    Dir.chdir(@old_dir)
    FileUtils.rm_rf(@tmp)
  end

  def init_cookbook
	::File.open('metadata.rb', 'wb+') do |f|
	  f.write <<-EOH
name             'yum-criteo'
maintainer       'Criteo'
maintainer_email 'j.mauro@criteo.com'
license          'All rights reserved'
description      "Update system to frozen"
long_description ""
version          '2.0.0'
	  EOH
	end
  end

  describe '.pusblish_ck' do
    it 'publish to supermarket' do
      init_cookbook
      s = CookbookRelease::Supermarket.new(opts)
      response = double('http response',
        body: "{}",
        code: "201"
      )
      expect(::Chef::CookbookSiteStreamingUploader).
        to receive(:post).
        with('http://a_url', 'a_name', 'a_file', anything()).
        and_return(response)
      expect { s.publish_ck('a_category') }.not_to raise_error
    end
  end
end
