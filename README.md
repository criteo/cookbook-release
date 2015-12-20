CookbookRelease
===============

Helper to release cookbooks. This motivation is to publish new version at each commit on master branch.

This helper will create tags, push them and publish to supermarket.

Usage
-----

Include cookbook-release into your `Gemfile`.

Require cookbook-release into the `metadata.rb` file and replace the version by the helper:

```
version          Release.current_version
```
