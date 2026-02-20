import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RiffRoutineApiService {
  RiffRoutineApiService._();
  static final instance = RiffRoutineApiService._();

  String get _baseUrl =>
      dotenv.env['RIFFROUTINE_API_URL'] ?? 'https://www.riffroutine.com';

  /// Send a 6-digit verification code to the given email.
  /// Returns true if the request succeeded (does NOT reveal whether user exists).
  Future<bool> sendLinkCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/send-link-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim(), 'app': 'smg'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verify the 6-digit code. Returns a result map on success, null on failure.
  /// Result keys: `verified` (bool), `hasSubscription` (bool), `tier` (String), `error` (String?)
  Future<Map<String, dynamic>?> verifyLinkCode(
      String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-link-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'code': code,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return null;
    }
  }
}
