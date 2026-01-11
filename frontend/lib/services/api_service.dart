import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiService {
  final String backendBaseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  ApiService({required this.backendBaseUrl});

  Future<Map<String, String>> _authHeaders() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      return { 'Authorization': 'Bearer $accessToken' };
    }
    
    return {};
  }

  Future<Map<String, dynamic>?> get(String path) async {
    try {
      final uri = Uri.parse('$backendBaseUrl$path');
      final headers = await _authHeaders();
      print('[API] GET $uri');
      print('[API] Headers: ${headers.keys.join(", ")}');
      final response = await http.get(uri, headers: headers);
      print('[API] GET $path - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('[API] GET $path - Error body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('[API] GET $path exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> post(String path, dynamic body) async {
    try {
      final uri = Uri.parse('$backendBaseUrl$path');
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      print('[API] POST $uri');
      print('[API] Headers: ${headers.keys.join(", ")}');
      final response = await http.post(uri, headers: headers, body: jsonEncode(body));
      print('[API] POST $path - Status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        print('[API] POST $path - Error body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('[API] POST $path failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> put(String path, dynamic body) async {
    try {
      final uri = Uri.parse('$backendBaseUrl$path');
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http.put(uri, headers: headers, body: jsonEncode(body));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('PUT request failed: $e');
      return null;
    }
  }

  Future<bool> delete(String path) async {
    try {
      final uri = Uri.parse('$backendBaseUrl$path');
      final headers = await _authHeaders();
      final response = await http.delete(uri, headers: headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('DELETE request failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> sync(Map<String, dynamic> payload) async {
    return post('/api/sync', payload);
  }
}
