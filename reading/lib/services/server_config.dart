import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _kHostKey = 'server.host';
  static const _kPortKey = 'server.port';

  static final ServerConfig instance = ServerConfig._();
  ServerConfig._();

  String host = '';
  int port = 0;

  bool get isConfigured => host.trim().isNotEmpty && port > 0;

  String get baseUrl {
    final h = host.trim();
    if (h.isEmpty || port <= 0) return '';
    return 'http://$h:$port';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    host = (prefs.getString(_kHostKey) ?? '').trim();
    port = prefs.getInt(_kPortKey) ?? 0;
  }

  Future<void> save({required String host, required int port}) async {
    final prefs = await SharedPreferences.getInstance();
    this.host = host.trim();
    this.port = port;
    await prefs.setString(_kHostKey, this.host);
    await prefs.setInt(_kPortKey, this.port);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    host = '';
    port = 0;
    await prefs.remove(_kHostKey);
    await prefs.remove(_kPortKey);
  }
}

















