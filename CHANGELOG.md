# Change Log
## [0.0.3](https://github.com/biocross/unlimit/releases/tag/0.0.3)
Released on 2019-08-23.

#### Added
- Unlimit now supports custom scripts after finishing! Just create an `.unlimit.yml` file in your project root, put your scripts in the `custom_scripts` key, and run unlimit.

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