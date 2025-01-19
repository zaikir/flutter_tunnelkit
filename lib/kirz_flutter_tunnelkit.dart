import 'kirz_flutter_tunnelkit_platform_interface.dart';

class FlutterTunnelkit {
  static Future<void> setup() {
    return KirzFlutterTunnelkitPlatform.instance.setup();
  }

  static Future<VpnStatus> getVpnStatus() {
    return KirzFlutterTunnelkitPlatform.instance.getVpnStatus();
  }

  static Future<VpnTrafficInfo> getTrafficInfo() async {
    return KirzFlutterTunnelkitPlatform.instance.getTrafficInfo();
  }

  static Stream<VpnStatus> get onVpnStatusChanged {
    return KirzFlutterTunnelkitPlatform.instance.onVpnStatusChanged;
  }

  static connect({
    required String hostname,
    required String username,
    required String password,
    required String config,
  }) async {
    return KirzFlutterTunnelkitPlatform.instance
        .connect(hostname: hostname, username: username, password: password, config: config);
  }

  static Future<void> disconnect() {
    return KirzFlutterTunnelkitPlatform.instance.disconnect();
  }
}

class VpnTrafficInfo {
  VpnTrafficInfo({required this.received, required this.sent});

  final double received;
  final double sent;
}

enum VpnStatus {
  invalid,
  disconnected,
  connecting,
  connected,
  reasserting,
  disconnecting,
  none,
  unknown
}
