import 'package:kirz_flutter_tunnelkit/kirz_flutter_tunnelkit.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kirz_flutter_tunnelkit_method_channel.dart';

abstract class KirzFlutterTunnelkitPlatform extends PlatformInterface {
  /// Constructs a KirzFlutterTunnelkitPlatform.
  KirzFlutterTunnelkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static KirzFlutterTunnelkitPlatform _instance = MethodChannelKirzFlutterTunnelkit();

  /// The default instance of [KirzFlutterTunnelkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelKirzFlutterTunnelkit].
  static KirzFlutterTunnelkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KirzFlutterTunnelkitPlatform] when
  /// they register themselves.
  static set instance(KirzFlutterTunnelkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setup();

  Future<VpnStatus> getVpnStatus();

  Future<VpnTrafficInfo> getTrafficInfo();

  Stream<VpnStatus> get onVpnStatusChanged;

  Future<void> connect({
    required String hostname,
    required String username,
    required String password,
    required String config,
  });

  Future<void> disconnect();
}
