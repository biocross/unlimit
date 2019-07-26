# frozen_string_literal: true

require 'unlimit/version'
require 'xcodeproj'
require 'securerandom'
require 'json'
require 'plist'

ProjectPathKey = 'project_path'
PlistPathKey = 'plist_path'
TargetNameKey = 'target_name'
InfoPlistBuildSettingKey = 'INFOPLIST_FILE'
ProductTypeApplicationTarget = 'com.apple.product-type.application'
Divider = '================================================'

module Unlimit
  class CLI
    def putsWithOverrides(parameter, value, flag)
      puts "Using #{parameter}: #{value}".green + " (Use flag --#{flag} to override)".yellow
    end

    def showVersion
      puts Divider
      puts "You're using unlimit version #{Unlimit::VERSION}".green
      puts 'https://github.com/biocross/unlimit'.yellow
      puts Divider
      abort
    end

    def start(options)
      puts Divider
      puts "            unlimit 🚀📲 (#{Unlimit::VERSION})       "
      puts '    Switching your project to Personal Team!    '.yellow
      puts Divider

      xcode_project_files = Dir.glob('*.xcodeproj')
      project_path = ''
      plist_path = ''
      target_name = ''
      extensions = []
      target = nil

      # Check for a valid xcode_project
      if xcode_project_files.count == 1 || options.key?(ProjectPathKey)
        project_path = if options.key?(ProjectPathKey)
                         options[ProjectPathKey]
                       else
                         xcode_project_files.first
                       end

        unless File.directory?(project_path)
          abort("Project not found at #{project_path}".red)
        end
        putsWithOverrides('project', project_path, ProjectPathKey)
      else
        abort('Please specify the .xcodeproj project file to use with the --project option like --project MyProject.xcodeproj'.red)
      end

      project = Xcodeproj::Project.open(project_path)

      if options.key?(TargetNameKey)
        target_name = options[TargetNameKey]
        target = project.targets.find { |t| t.name == target_name }
        abort "Couldn't find the target '#{target_name}'  in '#{project_path}'" if target.nil?
        puts "Using target #{target_name}"
      else
        project.targets.each do |current_target|
          next unless current_target.product_type == ProductTypeApplicationTarget
          target = current_target
          target_name = current_target.name
          putsWithOverrides('target', target_name, TargetNameKey)
          break
        end
      end

      if options.key?(PlistPathKey)
        plist_path = options[PlistPathKey]

        unless File.file?(plist_path)
          abort("Info.plist file not found at path: #{plist_path}".red)
        end
        puts "Using Info.plist at path #{plist_path}.".green
      else
        if target.build_configurations.count > 0
          build_settings = target.build_configurations.first.build_settings
          plist_path = build_settings[InfoPlistBuildSettingKey]
          putsWithOverrides('Info.plist', plist_path, PlistPathKey)
        end

        if plist_path.nil? || plist_path.empty?
          abort('Please specify the path to your main target\'s Info.plist file with the --plist option like --plist MyProject-Info.plist'.red)
        end
      end

      project.targets.each do |target|
        if target.product_type.include? 'app-extension'
          extensions.push(target.name)
        end
      end

      puts "================================================\n"

      # Turn off capabilities that require entitlements
      puts 'Turning OFF all Capabilities'.red
      project.root_object.attributes.each do |value|
        next unless value[0] == 'TargetAttributes'

        hash = value[1]
        hash.each do |_key, val|
          next unless val.key?('SystemCapabilities')

          capabilities = val['SystemCapabilities']
          capabilities.each do |key, val|
            if val.key?('enabled')
              puts ' Turning OFF ' + key
              capabilities[key]['enabled'] = '0'
            end
          end
        end
      end
      project.save

      # Remove Entitlements
      puts 'Clearing entitlements...'.red
      Dir.glob('**/*.entitlements').each do |source_file|
        empty_plist = {}.to_plist
        File.open(source_file, 'w') { |file| file.puts empty_plist }
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

      puts 'Enabling Automatic Code Signing...'.red
      system("bundle exec fastlane run automatic_code_signing use_automatic_signing:true targets:#{target_name}")

      # Remove App Extensions
      puts "Removing App Extensions: #{extensions.join(', ')}".red
      system("bundle exec configure_extensions remove #{project_path} #{target_name} #{extensions.join(' ')}")

      puts "\n#{Divider}"
      puts 'You\'re good to go! Just connect your device, switch to your \'Personal Team\', and hit run!'.green
      puts Divider
    end
  end
end
