# Unlimit

Unlimit is a simple tool to quickly run your app on your device without worrying about the 100 device limit per developer account set by Apple. It achieves this by switching your Xcode Project to the Personal Team.

### Why can't I just do it myself?

Well, you can, if your project is simple. However, if your project has capabilities like Push Notifications, Background Modes, App extensions, and more, things get complicated, since these require you to configure the Personal Team with all these entitlements. Unlimit get's rid of all this mess, and let's your focus on running the app on your device.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unlimit'
```

And then execute:

    $ bundle install && bundle exec unlimit

Or install it yourself as:

    $ gem install unlimit

## Usage

Just execute:

    $ bundle exec unlimit

and unlimit will do it's magic.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/biocross/unlimit

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).