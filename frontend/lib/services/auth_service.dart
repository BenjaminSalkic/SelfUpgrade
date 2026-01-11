import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:http/http.dart' as http;
import 'package:auth0_flutter/auth0_flutter.dart';
import 'token_storage.dart';
import 'api_service.dart';
import 'auth_service_web.dart' if (dart.library.io) 'auth_service_stub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'mood_service.dart';
import 'journal_service.dart';
import 'goal_service.dart';
import 'user_service.dart';
import 'dart:convert' show base64, utf8;

String? _getCapturedHash() {
  try {
    final main = _getMainModule();
    return main?._capturedHash;
  } catch (e) {
    return null;
  }
}

dynamic _getMainModule() {
  try {
    return (null as dynamic);
  } catch (e) {
    return null;
  }
}

class AuthConfig {
  final String? domain;
  final String? audience;
  final String? clientId;
  final String? frontendOrigin;
  final bool devBypass;

  AuthConfig({
    this.domain,
    this.audience,
    this.clientId,
    this.frontendOrigin,
    this.devBypass = false,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    final d = json['data'] ?? {};
    return AuthConfig(
      domain: d['auth0Domain'] as String?,
      audience: d['auth0Audience'] as String?,
      clientId: d['auth0ClientId'] as String?,
      frontendOrigin: d['frontendOrigin'] as String?,
      devBypass: d['devBypassAuth'] == true,
    );
  }
}

class AuthService extends ChangeNotifier {
  final String backendBaseUrl;
  AuthConfig? _config;
  Auth0? _auth0;
  final TokenStorage tokenStorage = TokenStorage();
  ApiService? _apiService;

  AuthService({required this.backendBaseUrl});

  AuthConfig? get config => _config;
  ApiService? get apiService => _apiService;

  Future<void> loadConfig() async {
    try {
      final uri = Uri.parse('$backendBaseUrl/auth/config');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        _config = AuthConfig.fromJson(jsonDecode(resp.body));
        if (_config?.domain != null && _config?.clientId != null) {
          _auth0 = Auth0(_config!.domain!, _config!.clientId!);
          _apiService = ApiService(backendBaseUrl: backendBaseUrl);
        }
        notifyListeners();
      } else {
        throw Exception('Failed to load auth config: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error loading auth config: $e');
    }
  }

  Future<dynamic> login({required String scheme, List<String>? scopes, String? audience}) async {
    if (_auth0 == null || _config == null) {
      try {
        await loadConfig();
      } catch (e) {
        throw Exception('Auth0 not configured and loadConfig failed: $e');
      }
    }
    if (_auth0 == null || _config == null) throw Exception('Auth0 not configured after loadConfig');
    
    if (kIsWeb) {
      _redirectToAuth0Login();
      return null;
    } else {
      final webAuth = _auth0!.webAuthentication(scheme: scheme);
      final result = await webAuth.login();
      if (result.accessToken != null) await tokenStorage.saveAccessToken(result.accessToken!);
      if (result.idToken != null) await tokenStorage.saveIdToken(result.idToken!);
      notifyListeners();
      return result;
    }
  }

  void _redirectToAuth0Login() {
    if (_config == null) throw Exception('Config not loaded');
    final domain = _config!.domain;
    final clientId = _config!.clientId;
    final redirectUri = Uri.encodeQueryComponent('${_config!.frontendOrigin}/callback');
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    
    final authorizeUrl = 'https://$domain/authorize?'
        'response_type=token%20id_token&'
        'client_id=$clientId&'
        'redirect_uri=$redirectUri&'
        'scope=openid%20profile%20email&'
        'audience=${Uri.encodeQueryComponent(_config!.audience ?? "")}&'
        'state=$state&'
        'nonce=${DateTime.now().millisecondsSinceEpoch}&'
        'connection=google-oauth2';
    
    redirectToUrl(authorizeUrl);
  }

  Future<void> handleCallback() async {
    String fragment = getLocationHash();
    
    if (kIsWeb && (fragment.isEmpty || !fragment.contains('access_token'))) {
      final savedHash = getSavedHash();
      if (savedHash.isNotEmpty && savedHash.contains('access_token')) {
        fragment = savedHash;
      }
    }
    
    if (fragment.isEmpty || !fragment.contains('access_token')) {
      if (fragment.contains('error')) {
        final params = Uri.splitQueryString(fragment.substring(1));
      }
            return;
    }
    
    final params = Uri.splitQueryString(fragment.substring(1));
    final accessToken = params['access_token'];
    final idToken = params['id_token'];
    
    if (accessToken != null) await tokenStorage.saveAccessToken(accessToken);
    if (idToken != null) await tokenStorage.saveIdToken(idToken);
    
    replaceHistoryState();
    notifyListeners();
  }

  Future<void> syncLocalData(Map<String, dynamic> payload) async {
    if (_apiService == null) throw Exception('API client not configured');
    await _apiService!.sync(payload);
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final idToken = await tokenStorage.getIdToken();
    if (idToken == null) {
      return null;
    }
    
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> claims = json.decode(decoded);
      
      return {
        'name': claims['name'],
        'email': claims['email'],
        'picture': claims['picture'],
        'sub': claims['sub'],
      };
    } catch (e) {
      print('Error decoding ID token: $e');
      return null;
    }
  }

  Future<void> logout() async {
    // Clear tokens first
    await tokenStorage.clear();

    // Cancel any scheduled notifications
    try {
      await NotificationService.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }

    // Clear all local user data using typed service methods
    try {
      await JournalService.clearAll();
      print('Cleared journal entries');
    } catch (e) {
      print('Error clearing journal entries: $e');
    }

    try {
      await GoalService.clearAll();
      print('Cleared goals');
    } catch (e) {
      print('Error clearing goals: $e');
    }

    try {
      await UserService.clearAll();
      print('Cleared users');
    } catch (e) {
      print('Error clearing users: $e');
    }

    try {
      await MoodService.clearAll();
      print('Cleared moods');
    } catch (e) {
      print('Error clearing moods: $e');
    }

    // Clear SharedPreferences caches
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_goal_id');
      // Clear notification settings too
      await prefs.remove('notifications_daily_enabled');
      await prefs.remove('notifications_sunday_enabled');
      await prefs.remove('notifications_goal_enabled');
      await prefs.remove('notifications_streak_enabled');
      await prefs.remove('notifications_smart_enabled');
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
    }

    notifyListeners();
  }

  Future<void> clearUserData() async {
  }
}
