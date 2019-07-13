require 'unlimit/version'
require 'xcodeproj'
require 'securerandom'
require 'json'
require 'plist'

ProjectPathKey = 'project_path'.freeze
PlistPathKey = 'plist_path'.freeze
TargetNameKey = 'target_name'.freeze
ProductTypeApplicationTarget = 'com.apple.product-type.application'.freeze

module Unlimit
  class CLI
    def start(options)
      puts 'Switching your project to Personal Team!'.yellow

      xcode_project_files = Dir.glob('*.xcodeproj')
      project_path = ''
      plist_path = ''
      target_name = ''
      extensions = []

      # Check for a valid xcode_project
      unless xcode_project_files.count == 1 || options.key?(ProjectPathKey)
        abort('Please specify the .xcodeproj project file to use with the --project option like --project MyProject.xcodeproj'.red)
      else 
        if options.key?(ProjectPathKey)
          project_path = options[ProjectPathKey]
        else
          project_path = xcode_project_files.first
        end

        unless File.directory?(project_path)
          abort("Project not found at #{project_path}".red)
        end

        puts "Using #{project_path}".green
      end

      unless options.key?(PlistPathKey)
        abort('Please specify the path to your main target\'s Info.plist file with the --plist option like --plist MyProject-Info.plist'.red)
      else 
        plist_path = options[PlistPathKey]

        unless File.file?(plist_path)
          abort("Plist file not found at #{plist_path}".red)
        end

        puts "Using Info.plist at #{plist_path}".green
      end

      project = Xcodeproj::Project.open(project_path)

      if options.key?(TargetNameKey)
        target_name = options[TargetNameKey]
        target = project.targets.find { |t| t.name == target_name }
        abort "Couldn't find the target '#{target_name}'  in '#{project_path}'" if target.nil?
        puts "Using target #{target_name}"
      else 
        for target in project.targets 
          if target.product_type == ProductTypeApplicationTarget
            target_name = target.name
            puts "Using target #{target_name}. If this is incorrect, please specify the target name with the --target option".green
            break;
          end
        end
      end

      for target in project.targets 
        if target.product_type.include? 'app-extension'
          extensions.push(target.name)
        end
      end
  
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
      puts "Removing App Extensions: #{extensions.join(', ')}".red
      system("bundle exec configure_extensions remove #{project_path} #{target_name} #{extensions.join(' ')}")

      puts 'You\'re good to go! Just connect your device, switch to your \'Personal Team\', and hit run!'.green
    end
  end
end
