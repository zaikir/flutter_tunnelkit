# kirz_flutter_tunnelkit

A new Flutter plugin project.

## Getting Started

This plugin project has been generated with `flutter pub init --plugin`.

TODO: write Readme.md

1. search for IPHONEOS_DEPLOYMENT_TARGET and replace to IPHONEOS_DEPLOYMENT_TARGET = 13.4;

2. add in Podfile
  pod "TunnelKit/Protocols/OpenVPN", :podspec => 'https://raw.githubusercontent.com/zaikir/ios-openvpn/master/TunnelKit.podspec'
  pod "TunnelKit/Extra/LZO", :podspec => 'https://raw.githubusercontent.com/zaikir/ios-openvpn/master/TunnelKit.podspec'

3. add in Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.4'
    end
  end
end

3. create new Network Extension (Packet Tunnel) with name VpnProviderExtension

4. paste this to VpnProviderExtension.entitlements (replace [bundle_id])
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.networking.networkextension</key>
	<array>
		<string>packet-tunnel-provider</string>
	</array>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.[bundle_id].VpnProviderExtension</string>
	</array>
	<key>keychain-access-groups</key>
	<array>
		<string>$(AppIdentifierPrefix)group.[bundle_id].VpnProviderExtension</string>
	</array>
</dict>
</plist>

5. paste this to PacketTunnelProvider.swift
import TunnelKit

class PacketTunnelProvider: OpenVPNTunnelProvider {
    override func startTunnel(
        options: [String: NSObject]? = nil,
        completionHandler: @escaping (Error?) -> Void
    ) {
        super.startTunnel(options: options, completionHandler: completionHandler)
        
        if false {
            let unusedVariable = "This code will never run"
            print(unusedVariable)
        }
        
        let groupIdentifier = "group.[bundle_id].VpnProviderExtension"
        let defaults = UserDefaults(suiteName: groupIdentifier)
        let interval = defaults?.integer(forKey: "dataCountInterval") ?? 1000
        self.dataCountInterval = interval
    }
}

6. add this to Runner.entitlements

<key>com.apple.developer.networking.networkextension</key>
<array>
  <string>packet-tunnel-provider</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
  <string>group.[bundle_id].VpnProviderExtension</string>
</array>
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)group.[bundle_id].VpnProviderExtension</string>
</array>

7. add this to Podfile (in main target)
target 'VpnProviderExtension' do
  use_frameworks!
  use_modular_headers!

  pod "TunnelKit/Protocols/OpenVPN", :podspec => 'https://raw.githubusercontent.com/zaikir/ios-openvpn/master/TunnelKit.podspec'
  pod "TunnelKit/Extra/LZO", :podspec => 'https://raw.githubusercontent.com/zaikir/ios-openvpn/master/TunnelKit.podspec'
end

