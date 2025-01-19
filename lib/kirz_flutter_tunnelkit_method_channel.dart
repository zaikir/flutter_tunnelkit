import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kirz_flutter_tunnelkit/constants.dart';
import 'package:kirz_flutter_tunnelkit/kirz_flutter_tunnelkit.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'kirz_flutter_tunnelkit_platform_interface.dart';

/// An implementation of [KirzFlutterTunnelkitPlatform] that uses method channels.
class MethodChannelKirzFlutterTunnelkit extends KirzFlutterTunnelkitPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('kirz_flutter_tunnelkit_method_channel');

  @visibleForTesting
  final eventChannel = const EventChannel('kirz_flutter_tunnelkit_event_channel');

  static Stream<VpnStatus>? _onVpnStatusChanged;

  @override
  Future<void> setup(
      {String? tunnelIdentifier, String? appGroup, String? configurationName}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final bundleId = packageInfo.packageName;

    final resultTunnelIdentifier = tunnelIdentifier ?? "$bundleId.$networkExtensionTargetName";
    final resultAppGroup = appGroup ?? "group.$resultTunnelIdentifier";
    final resultConfigurationName = configurationName ?? packageInfo.appName;

    await methodChannel.invokeMethod('setup', {
      'tunnelIdentifier': resultTunnelIdentifier,
      'appGroup': resultAppGroup,
      'configurationName': resultConfigurationName
    });
  }

  VpnStatus _mapStatus(String name) {
    switch (name) {
      case "invalid":
        return VpnStatus.invalid;
      case "disconnected":
        return VpnStatus.disconnected;
      case "connecting":
        return VpnStatus.connecting;
      case "connected":
        return VpnStatus.connected;
      case "reasserting":
        return VpnStatus.reasserting;
      case "disconnecting":
        return VpnStatus.disconnecting;
      case "none":
        return VpnStatus.none;
      case "unknown":
        return VpnStatus.unknown;
      default:
        throw Exception("Unknown status: $name");
    }
  }

  @override
  Future<VpnStatus> getVpnStatus() async {
    final status = await methodChannel.invokeMethod('getVpnStatus');

    return _mapStatus(status);
  }

  @override
  Future<VpnTrafficInfo> getTrafficInfo() async {
    final result = await methodChannel.invokeMethod<Map>('requestBytesCount');
    final map = Map<String, dynamic>.from(result ?? {});

    return VpnTrafficInfo(received: map['received'] ?? 0, sent: map['sent'] ?? 0);
  }

  @override
  Stream<VpnStatus> get onVpnStatusChanged {
    return _onVpnStatusChanged ??=
        eventChannel.receiveBroadcastStream('onVpnStatusChanged').map((event) => _mapStatus(event));
  }

  @override
  Future<void> connect(
      {required String hostname,
      required String username,
      required String password,
      required String config}) {
    return methodChannel.invokeMethod('connect',
        {'hostname': hostname, 'username': username, 'password': password, 'config': config});
  }

  @override
  Future<void> disconnect() {
    return methodChannel.invokeMethod('disconnect');
  }
}
