import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://buildmate-db.onrender.com/api';

  final http.Client _client = http.Client();

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _client.get(url);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    final jsonBody = body != null ? jsonEncode(body) : null;
    return await _client.post(url, headers: headers, body: jsonBody);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    final jsonBody = body != null ? jsonEncode(body) : null;
    return await _client.put(url, headers: headers, body: jsonBody);
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    final jsonBody = body != null ? jsonEncode(body) : null;
    return await _client.patch(url, headers: headers, body: jsonBody);
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _client.delete(url);
  }

  void dispose() {
    _client.close();
  }
}
