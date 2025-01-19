import Flutter
import NetworkExtension
import TunnelKit
import UIKit

public class KirzFlutterTunnelkitPlugin: NSObject, FlutterPlugin {
  // MARK: - Channels

  private static let methodChannelName = "kirz_flutter_tunnelkit_method_channel"
  private static let eventChannelName = "kirz_flutter_tunnelkit_event_channel"

  private var eventSink: FlutterEventSink?

  // MARK: - TunnelKit properties

  private var appGroup: String?
  private var tunnelIdentifier: String?
  private var configurationName: String?

  private var keychain: Keychain?
  private var vpn: OpenVPNProvider?
  private var previousStatus = "unknown"

  // MARK: - Plugin Registration

  public static func register(with registrar: FlutterPluginRegistrar) {
    // 1) Method channel for calling plugin methods from Dart
    let channel = FlutterMethodChannel(name: methodChannelName,
                                       binaryMessenger: registrar.messenger())

    // 2) Event channel for streaming status updates
    let eventChannel = FlutterEventChannel(name: eventChannelName,
                                           binaryMessenger: registrar.messenger())

    let instance = KirzFlutterTunnelkitPlugin()

    // Set the event channel’s handler
    eventChannel.setStreamHandler(instance)

    // Set the method channel’s handler
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // MARK: - Handle Method Calls

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setup":
      handleSetup(call: call, result: result)
    case "connect":
      handleConnect(call: call, result: result)
    case "disconnect":
      handleDisconnect(call: call, result: result)
    case "requestBytesCount":
      handleRequestBytesCount(call: call, result: result)
    case "getVpnStatus":
      handleGetVpnStatus(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - Event Channel (FlutterStreamHandler)

extension KirzFlutterTunnelkitPlugin: FlutterStreamHandler {
  public func onListen(withArguments _: Any?,
                       eventSink events: @escaping FlutterEventSink) -> FlutterError?
  {
    eventSink = events

    // Start listening for VPN status changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(vpnStatusDidChange(notification:)),
      name: VPN.didChangeStatus,
      object: nil
    )

    return nil
  }

  public func onCancel(withArguments _: Any?) -> FlutterError? {
    eventSink = nil

    // Stop listening for VPN status changes
    NotificationCenter.default.removeObserver(self,
                                              name: VPN.didChangeStatus,
                                              object: nil)
    return nil
  }
}

// MARK: - Private Methods

extension KirzFlutterTunnelkitPlugin {
  private func ensureSetup() throws {
    guard keychain != nil, vpn != nil else {
      throw NSError(domain: "FlutterTunnelKit",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Call setup() first."])
    }
  }

  @objc private func vpnStatusDidChange(notification _: NSNotification) {
    let currentStatus = vpn?.status.rawValue ?? "unknown"
    guard previousStatus != currentStatus else { return }

    previousStatus = currentStatus

    // Send status event back to Flutter
    eventSink?(["status": currentStatus])
  }
}

// MARK: - Handler Implementations

extension KirzFlutterTunnelkitPlugin {
  private func handleSetup(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let tunnelIdentifier = args["tunnelIdentifier"] as? String,
          let appGroup = args["appGroup"] as? String,
          let configurationName = args["configurationName"] as? String
    else {
      result(FlutterError(code: "InvalidArguments",
                          message: "Missing arguments for setup",
                          details: nil))
      return
    }

    self.tunnelIdentifier = tunnelIdentifier
    self.appGroup = appGroup
    self.configurationName = configurationName

    vpn = OpenVPNProvider(bundleIdentifier: tunnelIdentifier)
    keychain = Keychain(group: appGroup)

    // Prepare the VPN
    vpn?.prepare {
      result(nil) // success
    }
  }

  private func handleConnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      try ensureSetup()

      guard let args = call.arguments as? [String: Any],
            let configString = args["config"] as? String,
            let hostname = args["hostname"] as? String,
            let username = args["username"] as? String,
            let password = args["password"] as? String
      else {
        result(FlutterError(code: "InvalidArguments",
                            message: "Missing arguments for connect",
                            details: nil))
        return
      }

      previousStatus = "unknown"

      let credentials = OpenVPN.Credentials(username, password)
      let configuration = try Configuration.make(configString: configString, hostname: hostname)

      try keychain?.set(password: credentials.password,
                        for: credentials.username,
                        context: tunnelIdentifier!)

      let proto = try configuration.generatedTunnelProtocol(
        withBundleIdentifier: tunnelIdentifier!,
        appGroup: appGroup!,
        context: tunnelIdentifier!,
        username: credentials.username
      )

      let vpnConfiguration = NetworkExtensionVPNConfiguration(
        title: configurationName!,
        protocolConfiguration: proto,
        onDemandRules: []
      )

      vpn?.reconnect(configuration: vpnConfiguration) { error in
        if let error = error {
          result(FlutterError(code: "UnableToConnect",
                              message: error.localizedDescription,
                              details: nil))
          return
        }
        result(nil) // success
      }
    } catch {
      result(FlutterError(code: "ConfigurationError",
                          message: "\(error)",
                          details: nil))
    }
  }

  private func handleDisconnect(call _: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      try ensureSetup()
      vpn?.disconnect(completionHandler: nil)
      result(nil)
    } catch {
      result(FlutterError(code: "NotSetup",
                          message: "\(error)",
                          details: nil))
    }
  }

  private func handleRequestBytesCount(call _: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      try ensureSetup()
      vpn?.requestBytesCount { info in
        let received = info?.0 ?? 0
        let sent = info?.1 ?? 0
        result(["received": received, "sent": sent])
      }
    } catch {
      result(FlutterError(code: "NotSetup",
                          message: "\(error)",
                          details: nil))
    }
  }

  private func handleGetVpnStatus(call _: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      try ensureSetup()
      let status = vpn?.status.rawValue ?? "unknown"
      result(status)
    } catch {
      result(FlutterError(code: "NotSetup",
                          message: "\(error)",
                          details: nil))
    }
  }
}
