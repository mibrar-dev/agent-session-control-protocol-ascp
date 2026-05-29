class TestData {
  static const String daemonHost = '127.0.0.1';
  static const int daemonPort = 8767;
  static const int wsPort = 8765;

  static String pairingCode(String code) => '$daemonHost:$daemonPort:$code';
}
