require 'unlimit/version'
require 'xcodeproj'
require 'securerandom'
require 'json'
require 'plist'

module Unlimit
  class CLI
    def start
      puts 'Switching your project to Personal Team!'.yellow

      project_path = ''
      plist_path = ''
      target_name = ''
      extension_name = ''

      project = Xcodeproj::Project.open(project_path)

      # Turn off capabilities that require entitlements
      puts 'Turning OFF all Capabilities'.red
      for value in project.root_object.attributes do
        if value[0] == 'TargetAttributes'
          hash = value[1]
          for key, val in hash do
            if val.key?('SystemCapabilities') 
              capabilities = val['SystemCapabilities']
              for key, val in capabilities
                if val.key?('enabled')
                  puts ' Turning OFF ' + key
                  capabilities[key]['enabled'] = '0'
                end
              end
            end
          end
        end
      end
      project.save()

      # Remove Entitlements
      puts 'Clearing entitlements...'.red
      Dir.glob('**/*.entitlements').each do |source_file|
        empty_plist = {}.to_plist
        File.open(source_file, 'w') { |file| file.puts empty_plist  }
      end

      # Remove Capability Keys from Plist
      puts 'Removing capabilities from Info.plist...'.red
      info_plist = Plist.parse_xml(plist_path)
      info_plist.delete('UIBackgroundModes')
      File.open(plist_path, 'w') { |file| file.puts info_plist.to_plist }

      # Change Bundle Identifier
      puts 'Changing bundle identifier...'.red
      bundle_identifier = "com.unlimit.#{SecureRandom.uuid}"
      system("bundle exec fastlane run update_app_identifier plist_path:#{plist_path} app_identifier:#{bundle_identifier}")

      # Remove App Extensions
      puts 'Removing App Extensions...'.red
      system("bundle exec configure_extensions remove #{project_path} #{target_name} #{extension_name}")

      puts 'You\'re good to go! Just connect your device, switch to your \'Personal Team\', and hit run!'.green
    end
  end
end
