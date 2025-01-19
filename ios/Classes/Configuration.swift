import Foundation
import TunnelKit

struct Configuration {
    static func make(configString: String, hostname: String) throws -> OpenVPNTunnelProvider.Configuration {
        let config = try OpenVPN.ConfigurationParser.parsed(fromLines: configString.components(separatedBy: "\n"))

        var sessionBuilder = config.configuration.builder()
        sessionBuilder.hostname = hostname

        var builder = OpenVPNTunnelProvider.ConfigurationBuilder(sessionConfiguration: sessionBuilder.build())
        builder.shouldDebug = true
        builder.masksPrivateData = false

        return builder.build()
    }
}
