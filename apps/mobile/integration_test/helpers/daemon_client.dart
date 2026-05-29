import 'dart:convert';
import 'package:http/http.dart' as http;

class DaemonClient {
  static const String adminBaseUrl = 'http://127.0.0.1:8767';
  static const String wsUrl = 'ws://127.0.0.1:8765';

  static Future<bool> isDaemonRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$adminBaseUrl/admin/pairing/sessions'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> createPairingSession() async {
    final response = await http.post(
      Uri.parse('$adminBaseUrl/admin/pairing/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requested_scopes': ['sessions.read', 'sessions.write'],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create pairing session: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> approvePairingSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$adminBaseUrl/admin/pairing/sessions/$sessionId/approve'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve pairing session: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getPairingSessions() async {
    final response = await http.get(
      Uri.parse('$adminBaseUrl/admin/pairing/sessions'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get pairing sessions: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final sessions = data['sessions'] as List;
    return sessions.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await http.get(
      Uri.parse('$adminBaseUrl/admin/sessions'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get sessions: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final sessions = data['sessions'] as List;
    return sessions.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getApprovals() async {
    final response = await http.get(
      Uri.parse('$adminBaseUrl/admin/approvals'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get approvals: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final approvals = data['approvals'] as List;
    return approvals.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getTrustedDevices() async {
    final response = await http.get(
      Uri.parse('$adminBaseUrl/admin/trusted-devices'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get trusted devices: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final devices = data['devices'] as List;
    return devices.cast<Map<String, dynamic>>();
  }
}
