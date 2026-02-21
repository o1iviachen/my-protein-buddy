platform :ios, '16.2'

target 'my-protein-buddy' do
  use_frameworks!

  # Pods for my-protein-buddy
  pod 'Firebase/Auth', '~> 11.13.0'
  pod 'Firebase/Firestore', '~> 11.13.0'
  pod 'GoogleSignIn'
  pod 'IQKeyboardManagerSwift'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'BoringSSL-GRPC'
        target.source_build_phase.files.each do |file|
          if file.settings && file.settings['COMPILER_FLAGS']
            flags = file.settings['COMPILER_FLAGS'].split
            flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
            file.settings['COMPILER_FLAGS'] = flags.join(' ')
          end
        end
      end
    end
  end
end
