import 'package:local_auth/local_auth.dart';

abstract interface class LocalAuthGate {
  Future<bool> confirm(String reason);
}

abstract interface class LocalAuthenticator {
  Future<bool> canAuthenticate();

  Future<bool> authenticate(String reason);
}

class DeviceLocalAuthGate implements LocalAuthGate {
  DeviceLocalAuthGate({LocalAuthenticator? authenticator})
    : _authenticator = authenticator ?? LocalAuthPluginAuthenticator();

  final LocalAuthenticator _authenticator;

  @override
  Future<bool> confirm(String reason) async {
    if (!await _authenticator.canAuthenticate()) {
      return false;
    }
    return _authenticator.authenticate(reason);
  }
}

class LocalAuthPluginAuthenticator implements LocalAuthenticator {
  LocalAuthPluginAuthenticator({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> canAuthenticate() {
    return _authentication.isDeviceSupported();
  }

  @override
  Future<bool> authenticate(String reason) {
    return _authentication.authenticate(
      localizedReason: reason,
      persistAcrossBackgrounding: true,
    );
  }
}

class AllowingLocalAuthGate implements LocalAuthGate {
  const AllowingLocalAuthGate();

  @override
  Future<bool> confirm(String reason) async => true;
}
