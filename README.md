CookbookRelease
===============

[![Build Status](https://travis-ci.org/criteo/cookbook-release.svg?branch=master)](https://travis-ci.org/criteo/cookbook-release)
[![Gem Version](https://badge.fury.io/rb/cookbook-release.svg)](https://badge.fury.io/rb/cookbook-release)

Helper to release cookbooks. This motivation is to publish new version at each commit on master branch from the CI.

This helper will create tags, push them and publish to supermarket.

Usage
-----

Include cookbook-release into your `Gemfile`.

Require cookbook-release into the `metadata.rb` file and replace the version by the helper:

```
require 'cookbook-release'
version          Release.current_version(__FILE__)
```

Include the rake tasks in your Rakefile:

```
require 'cookbook-release'
CookbookRelease::Rake::CookbookTask.new
```

Then you can publish on your supermarket using:

```
export SUPERMARKET_CLIENTKEYFILE=/tmp/my_key.pem
export SUPERMARKET_USERID=my_username
export SUPERMARKET_URL="http://supermarket.chef.io/api/v1/cookbooks"
export NO_PROMPT=""
export SUPERMARKET_NO_SSL_VERIFY=1
rake release!
```

Optional environment variables:

```
export COOKBOOK_CATEGORY="Other" # defaults to Other
```

Note: this setup is intended to be used in a CI system such as jenkins or travis.
