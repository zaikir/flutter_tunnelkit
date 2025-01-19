#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint kirz_flutter_tunnelkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'kirz_flutter_tunnelkit'
  s.version          = '0.1.0'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.4'

  s.dependency 'TunnelKit/Protocols/OpenVPN'
  s.dependency 'TunnelKit/Extra/LZO'
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'kirz_flutter_tunnelkit_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end