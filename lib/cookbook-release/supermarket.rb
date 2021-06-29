require 'chef/cookbook_loader'
require 'chef/cookbook/cookbook_version_loader'
require 'chef/cookbook_uploader'
require 'chef/cookbook_site_streaming_uploader'
require 'chef/mixin/shell_out'
require 'json'

module CookbookRelease
  class Supermarket

    # This code is adapted from "knife cookbook share" and travis dpl provider
    # for supermarket.

    def initialize(opts={})
      @url        = opts[:url] || ENV['SUPERMARKET_URL'] || (raise "Require a supermarket url")
      @user_id    = opts[:user_id] || ENV['SUPERMARKET_USERID'] || (raise "Require a user id")
      @client_key = opts[:client_key_file] || ENV['SUPERMARKET_CLIENTKEYFILE'] || (raise "Require a client key file")
      Chef::Config[:ssl_verify_mode] = :verify_none if ENV['SUPERMARKET_NO_SSL_VERIFY']
    end

    include ::Chef::Mixin::ShellOut

    def publish_ck(category, path = nil)
      ck = ::Chef::Cookbook::CookbookVersionLoader.new(path || '.')
      ck.load!
      cookbook = ck.cookbook_version
      # we have to provide a rest option otherwise it will try to load a
      # client.pem key
      ::Chef::CookbookUploader.new(cookbook, rest: 'fake_rest').validate_cookbooks

      tmp_cookbook_dir = Chef::CookbookSiteStreamingUploader.create_build_dir(cookbook)
      begin
        shell_out!("tar -czf #{cookbook.name}.tgz #{cookbook.name}", :cwd => tmp_cookbook_dir)
      rescue StandardError => e
        raise "Impossible to make a tarball out of the cookbook, #{e}"
      end

      begin
        upload("#{tmp_cookbook_dir}/#{cookbook.name}.tgz", category)
        puts "Uploaded to supermarket #{@url}"
        FileUtils.rm_rf tmp_cookbook_dir
      rescue StandardError => e
        $stderr.puts "Impossible to upload the cookbook to supermarket: #{e}"
        raise
      end
    end

    def upload(filename, category)
      http_resp = ::Chef::CookbookSiteStreamingUploader.post(
        @url,
        @user_id,
        @client_key,
        {
          tarball: File.open(filename),
          cookbook: { category: category }.to_json,
        })
      res = ::Chef::JSONCompat.from_json(http_resp.body)
      if http_resp.code.to_i != 201
        if res['error_messages']
          if res['error_messages'][0] =~ /Version already exists/
            raise "The same version of this cookbook already exists on the Opscode Cookbook Site."
          else
            raise "#{res['error_messages'][0]}"
          end
        else
          raise "Unknown error while sharing cookbook\nServer response: #{http_resp.body}"
        end
      end
    end
  end
end
