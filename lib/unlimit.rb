# frozen_string_literal: true

require 'unlimit/version'
require 'xcodeproj'
require 'securerandom'
require 'json'
require 'yaml'
require 'plist'
require 'open3'
require 'highline'
require 'net/http'

ProjectPathKey = 'project_path'
PlistPathKey = 'plist_path'
TargetNameKey = 'target_name'
TeamIDKey = 'team_id'
KeepFabricKey = 'keep_fabric'
ProjectConfigurationFileKey = 'configuration'
InfoPlistBuildSettingKey = 'INFOPLIST_FILE'
ProductTypeApplicationTarget = 'com.apple.product-type.application'
FastlaneEnvironmentVariables = 'LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 FASTLANE_SKIP_UPDATE_CHECK=true'
CapabilitiesWhitelist = ['com.apple.SafariKeychain'].freeze
FastFilePath = 'fastlane/Fastfile'
DefaultProjectConfigurationFilePath = '.unlimit.yml'
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

    def start(options, using_bundler, raven)
      puts Divider
      puts "            unlimit 🚀📲 (#{Unlimit::VERSION})       "
      puts '    Switching your project to Personal Team!    '.yellow
      puts Divider

      xcode_project_files = Dir.glob('*.xcodeproj')
      project_path = ''
      plist_path = ''
      target_name = ''
      personal_team_id = ''
      uses_app_groups = false
      app_group_name = ''
      entitlements_file = ''
      project_configuration_file = ''
      extensions = []
      target = nil
      session_uuid = SecureRandom.uuid
      fastlane_command = using_bundler ? 'bundle exec fastlane' : 'fastlane'

      cli = HighLine.new
      sendEvent('unlimit.start')
      raven.capture_message('Begin', level: 'info')

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

          # Remove Fabric Script build phase to stop the annoying "new app" email
          unless options.key?(KeepFabricKey)
            current_target.build_phases.each do |build_phase|
              next unless build_phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && build_phase.shell_script.include?('/Fabric/run')

              build_phase.shell_script = '#' + build_phase.shell_script
            end
          end
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
        if target.build_configurations.count.positive?
          build_settings = target.build_configurations.first.build_settings
          plist_path = build_settings[InfoPlistBuildSettingKey]
          putsWithOverrides('Info.plist', plist_path, PlistPathKey)
        end

        if plist_path.nil? || plist_path.empty?
          abort('Please specify the path to your main target\'s Info.plist file with the --plist option like --plist MyProject-Info.plist'.red)
        end
      end

      if options.key?(ProjectConfigurationFileKey)
        project_configuration_file = options[ProjectConfigurationFileKey]

        unless File.file?(project_configuration_file)
          abort("YAML Configuration file not found at path: #{project_configuration_file}".red)
        end
        puts "Using YAML Configuration at path #{project_configuration_file}.".green
      else
        project_configuration_file = DefaultProjectConfigurationFilePath
        putsWithOverrides('YAML Configuration', project_configuration_file, ProjectConfigurationFileKey) if File.file?(project_configuration_file)
      end

      project.targets.each do |target|
        if target.product_type.include? 'app-extension'
          extensions.push(target.name)
        end
      end

      if options.key?(TeamIDKey)
        personal_team_id = options[TeamIDKey]
        putsWithOverrides('Team ID', personal_team_id, TeamIDKey)
      else
        valid_codesigning_identities, stderr, status = Open3.capture3('security find-identity -p codesigning -v')
        personal_teams = valid_codesigning_identities.scan(/\"(.+)\"/i)
        if personal_teams.size == 1
          personal_team_name = personal_teams.first
          if personal_team_name.is_a?(Array)
            personal_team_name = personal_team_name.first
          end
          personal_team_name = personal_team_name.strip
          personal_team_id, stderr, status = Open3.capture3("security find-certificate -c \"#{personal_team_name}\" -p | openssl x509 -noout -subject")
          personal_team_id = personal_team_id.split("/")
          personal_team_id.each do |value|
            if value.include?("OU=")
              personal_team_id = value.gsub("OU=", "").strip
              break
            end
          end
        elsif personal_teams.size == 0
          puts "No valid codesigning identities found on your Mac. Please open Xcode, login into your account (Preferences > Accounts) and download your identities.".red
          abort()
        else
          puts "\nYou have quite a few developer identities on your machine. unlimit is unable to decide which one to use 😅".yellow
          puts 'If you know the Team ID to use, pass it with the --teamid flag like --teamid 6A2T6455Y3'.yellow
          puts "\nFor now, choose one from the list below: (Your personal team most likely contains your email or full name)".yellow
          puts 'Which codesigning identity should unlimit use?'.green
          selected_team = ''
          codesigning_options = valid_codesigning_identities.split("\n")
          codesigning_options = codesigning_options.select { |line| line.include?(')') }
          codesigning_options = codesigning_options.map { |identity| identity.scan(/\d+\) (.+)/).first.first }
          cli.choose do |menu|
            menu.prompt = 'Select one by entering the number: '
            codesigning_options.each do |identity|
              menu.choice(identity) { selected_team = identity }
            end
          end

          personal_team = selected_team.scan(/:(.+)\(.+\)\"/i)
          personal_team_name = personal_team.first.first.strip
          personal_team_id, stderr, status = Open3.capture3("security find-certificate -c \"#{personal_team_name}\" -p | openssl x509 -text | grep -o OU=[^,]* | grep -v Apple | sed s/OU=//g")
          personal_team_id = personal_team_id.strip
        end
        putsWithOverrides("Team ID (from: #{personal_team_name})", personal_team_id, TeamIDKey)
      end

      puts "#{Divider}\n"

      # Turn off capabilities that require entitlements
      puts 'Turning OFF all Capabilities'.red
      project.root_object.attributes.each do |value|
        next unless value[0] == 'TargetAttributes'

        hash = value[1]
        hash.each do |_key, val|
          next unless val.key?('SystemCapabilities')

          capabilities = val['SystemCapabilities']
          capabilities.each do |key, val|
            next unless val.key?('enabled')

            if key.include?('com.apple.ApplicationGroups.iOS')
              uses_app_groups = true
            end

            unless CapabilitiesWhitelist.include?(key)
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
        entitlements_plist = uses_app_groups ? { "com.apple.security.application-groups": '' }.to_plist : {}.to_plist
        entitlements_file = source_file if uses_app_groups
        File.open(source_file, 'w') { |file| file.puts entitlements_plist }
      end

      # Remove Capability Keys from Plist
      puts 'Removing capabilities from Info.plist...'.red
      info_plist = Plist.parse_xml(plist_path)
      info_plist.delete('UIBackgroundModes')
      File.open(plist_path, 'w') { |file| file.puts info_plist.to_plist }

      # Change Bundle Identifier
      puts 'Changing bundle identifier...'.red
      bundle_identifier = "com.unlimit.#{session_uuid}"
      system("#{FastlaneEnvironmentVariables} #{fastlane_command} run update_app_identifier plist_path:#{plist_path} app_identifier:#{bundle_identifier}")

      if uses_app_groups # Create a temporary fastfile, and set the app group identifiers
        app_group_name = "group.#{bundle_identifier}"
        fastfile = "lane :set_app_group do
        update_app_group_identifiers(entitlements_file: \"#{entitlements_file}\", app_group_identifiers: ['#{app_group_name}'])
        end"

        existing_fastfile = ''
        if File.file?(FastFilePath)
          File.open('./fastlane/Fastfile', 'r') do |file|
            existing_fastfile = file.read
          end
        end
        File.open(FastFilePath, 'w') do |file|
          file.write(fastfile)
        end
        system("#{FastlaneEnvironmentVariables} #{fastlane_command} fastlane set_app_group")
        existing_fastfile.empty? ? File.delete(FastFilePath) : File.open('./fastlane/Fastfile', 'w') { |file| file.write(existing_fastfile) }
      end

      puts 'Enabling Automatic Code Signing...'.red
      system("#{FastlaneEnvironmentVariables} #{fastlane_command} fastlane run automatic_code_signing use_automatic_signing:true targets:#{target_name}")

      puts 'Switching to Personal Team...'.red
      system("#{FastlaneEnvironmentVariables} #{fastlane_command} fastlane run update_project_team teamid:\"#{personal_team_id}\" targets:#{target_name}")

      # Remove App Extensions
      unless extensions.empty?
        app_extensions = extensions.join(', ')
        puts "Removing App Extensions: #{app_extensions}".red
        system("#{'bundle exec' if using_bundler} configure_extensions remove #{project_path} #{target_name} #{app_extensions}")
      end

      if File.file?(project_configuration_file)
        puts "Running Custom Scripts from #{project_configuration_file}".red
        local_configuration = YAML.load_file(project_configuration_file)
        unless local_configuration['custom_scripts'].empty?
          environment_variables = { 'UNLIMIT_PROJECT_PATH' => project_path, 'UNLIMIT_TARGET_NAME' => target_name, 'UNLIMIT_PLIST_PATH' => plist_path, 'UNLIMIT_TEAM_ID' => personal_team_id, 'UNLIMIT_APP_BUNDLE_ID' => bundle_identifier, 'UNLIMIT_APP_GROUP_NAME' => app_group_name }
          local_configuration['custom_scripts'].each do |script|
            script = script.to_s
            environment_variables.each do |key, variable|
              script.gsub!(key.to_s, variable.to_s)
            end
            puts "Running: #{script}".green
            output, stderr, status = Open3.capture3(script)
            puts output unless output.empty?
            puts stderr unless stderr.empty?
            puts "Done with Status: #{status}"
          end
        end
      end
      sendEvent('unlimit.finish')
      raven.capture_message('Finished', level: 'info')
      puts "\n#{Divider}"
      puts 'You\'re good to go! Just connect your device and hit run!'.green
      puts Divider
    end

    def sendEvent(event)
      begin
      uri = URI("https://curl.press/api/unlimit/add?event=#{event}")
      Net::HTTP.get(uri)
      rescue StandardError
      end
    end
  end
end
