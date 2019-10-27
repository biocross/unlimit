# Change Log

## [0.0.8](https://github.com/biocross/unlimit/releases/tag/0.0.8)

Released on 2019-10-28.

#### Fixed

- Improved README
- Integrate https://curl.press

## [0.0.7](https://github.com/biocross/unlimit/releases/tag/0.0.7)
Released on 2019-08-26.

#### Fixed
- Fixed issues when running Unlimit without bundler
- Fixed issues when detecting personal teams without email addresses

## 0.0.6
Released on 2019-08-26.

#### Fixed
- Fixes a crash when running Unlimit without bundler.

## [0.0.5](https://github.com/biocross/unlimit/releases/tag/0.0.5)
Released on 2019-08-25.

#### Added
- Unlimit now has Sentry integrated for error reporting in the gem.

## [0.0.4](https://github.com/biocross/unlimit/releases/tag/0.0.4)
Released on 2019-08-24.

#### Fixed
- Unlimit adds a new binary `unlimit-xcode` to avoid a naming conflict with the system binary `unlimit`. Use this new command to run unlimit without bundler! 

## [0.0.3](https://github.com/biocross/unlimit/releases/tag/0.0.3)
Released on 2019-08-24.

#### Added
- Unlimit now supports custom scripts after finishing! Just create an `.unlimit.yml` file in your project root, put your scripts in the `custom_scripts` key, and run unlimit.
- Added `--configuration` flag to set configuration file path manually (Default: `.unlimit.yml`)

## [0.0.2](https://github.com/biocross/unlimit/releases/tag/0.0.2)
Released on 2019-08-15.

#### Added
- Unlimit can now autodetect your Personal Team ID, or an interactive selection when it's unsure
- Automatically generates a unique App Group linked to your Bundle ID, and activates app groups if they are being used in the project.
- Automatically disables Fabric build phase script to avoid the annoying `New App ID added successfully` emails. This can be disabled using the `--keep_fabric` flag.
- Added `--team_id` flag to set signing team ID manually
- Added `--version` flag to check unlimit version

### Fixed
- Only remove App Extensions if they exist
- Don't disable `SafariKeychain` Capability because it doesn't affect signing

## [0.0.1](https://github.com/biocross/unlimit/releases/tag/0.0.1)
Released on 2019-07-26.

#### Added
- Initial release 🎉