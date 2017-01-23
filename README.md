CookbookRelease
===============

[![Build Status](https://travis-ci.org/criteo/cookbook-release.svg?branch=master)](https://travis-ci.org/criteo/cookbook-release)
[![Gem Version](https://badge.fury.io/rb/cookbook-release.svg)](https://badge.fury.io/rb/cookbook-release)

Helper to release cookbooks. This motivation is to publish new version at each commit on master branch from the CI.

This helper will create tags, push them and publish to supermarket.

Daily use
---------

cookbook-release reads commit messages since last release and suggest a new version accordingly.

The following table describes the word used to detect patch/minor/major version changes:

| Version change | Words                                     |
|----------------|-------------------------------------------|
| Patch          | _fix_, _bugfix_, _[Patch]_                |
| Major          | _breaking_, _[Major]_                     |
| Minor          | Default case if none of the above matches |

Those words are detected in the commit subject only (not in the fully message).

Examples of messages:
- [Breaking] Remove all migration code
- Fix migration code for old centos versions


One-time setup (for cookbooks)
-----

Include cookbook-release into your `Gemfile`.
Put `metadata.rb` inside the `chefignore` file (required if berkshelf >= 5.4.0).

Require cookbook-release into the `metadata.rb` file and replace the version by the helper:

```
require 'cookbook-release'
version ::CookbookRelease::Release.current_version(__FILE__)
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


Changelog generation for chef-repositories
----

Using:
```
require 'cookbook-release'
CookbookRelease::Rake::RepoTask.new
```

will allow to create tasks to generate html changelog between HEAD and master branch. It aims to make some changes more visible such as [Risky] tag (or any tag used for major changes).
