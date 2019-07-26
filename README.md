# Unlimit 🚀📲

Unlimit is a simple tool to quickly run your app on your device without worrying about the 100 device limit per developer account set by Apple. It achieves this by temporarily switching your Xcode Project to your personal developer account (`Personal Team`).

> In a nutsell, unlimit fixes this:

<img width="350" src="https://github.com/biocross/unlimit/raw/master/images/max_devices.png" alt="Xcode Device Limit Reached Error">

**Note that all changes unlimit makes to your project are local on your mac, and do not in anyway affect the configuration on your Apple Developer Portal.**

### Why can't I just do it myself?

Well, you can, if your project is simple. However, if your project has capabilities like **Push Notifications**, **Background Modes** & **App Extensions**, things get complicated, since these require you to configure your `Personal Team` with all these entitlements. Unlimit gets rid of all this mess, and gets you quickly up and running on your device.

### What's the catch?

Well, since unlimit temporarily removes capabilities like **App Extensions, Push Notifications** & more from your project, you **cannot** test these features on your device when using your personal team.

### How do I undo unlimit's changes?

We recommend you run unlimit when you have no staged changes, so that you can simple go back by running `git reset --hard` when you're done testing on your device.

## Installation

Add this line to your app's Gemfile:

```ruby
gem 'unlimit'
```

And then install it using [bundler](https://bundler.io/) by executing:

    $ bundle install

If your iOS project does not have a `Gemfile` yet, [learn how to set it up here](https://www.mokacoding.com/blog/ruby-for-ios-developers-bundler/).

## Usage

After installing the gem, just run:

    $ bundle exec unlimit

and unlimit will do it's magic.

## Parameters

| Parameter | Description | Example |
| --- | --- | --- |
| `project` | The **.xcodeproj** project file to use | `--project MyApp.xcodeproj` |
| `target`  | The **app target** you want to run on your device | `--target MyApp` |
| `plist`   | The **path** to your app's **Info.plist** file | `--plist MyApp/MyApp-Info.plist` |

## Contributing

Bug reports and pull requests are welcome. Any feedback or feature suggesions are also encouraged.

## More FAQs

### Do I require a paid apple developer account to use this?

No, you can get a `personal team` using a free Apple Developer Account, since Apple now allows testing on device with a free developer accounts as well.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
