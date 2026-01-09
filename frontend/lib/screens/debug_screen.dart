import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';
import '../services/journal_service.dart';
import '../services/goal_service.dart';
import '../services/user_service.dart';
import '../models/journal_entry.dart';
import '../models/goal.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String? _accessToken;
  String? _idToken;
  int _journalCount = 0;
  int _goalsCount = 0;
  bool _hasUser = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() => _loading = true);
    
    final tokenStorage = TokenStorage();
    final accessToken = await tokenStorage.getAccessToken();
    final idToken = await tokenStorage.getIdToken();
    
    final journals = JournalService.getAll();
    final goals = GoalService.getAll();
    final user = UserService.getCurrent();
    
    setState(() {
      _accessToken = accessToken;
      _idToken = idToken;
      _journalCount = journals.length;
      _goalsCount = goals.length;
      _hasUser = user != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Debug Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection('Auth Tokens', [
                  _buildInfoRow('Access Token', _accessToken != null ? '✅ Present (${_accessToken!.length} chars)' : '❌ Missing'),
                  if (_accessToken != null)
                    _buildCopyButton('Copy Access Token', _accessToken!),
                  _buildInfoRow('ID Token', _idToken != null ? '✅ Present (${_idToken!.length} chars)' : '❌ Missing'),
                  if (_idToken != null)
                    _buildCopyButton('Copy ID Token', _idToken!),
                ]),
                const SizedBox(height: 20),
                _buildSection('Local Data (Hive)', [
                  _buildInfoRow('Journal Entries', '$_journalCount'),
                  _buildInfoRow('Goals', '$_goalsCount'),
                  _buildInfoRow('User Profile', _hasUser ? '✅ Exists' : '❌ Not set'),
                ]),
                const SizedBox(height: 20),
                _buildSection('Backend Status', [
                  _buildInfoRow('Backend URL', 'http://localhost:3001'),
                  ElevatedButton(
                    onPressed: _testBackendConnection,
                    child: const Text('Test Backend Connection'),
                  ),
                ]),
                const SizedBox(height: 20),
                if (_accessToken == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ No Access Token Found',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You need to login for sync to work. Without an access token, all API requests will fail with "Unauthorized".',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Divider(color: Colors.grey),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label copied to clipboard')),
          );
        },
        icon: const Icon(Icons.copy, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _testBackendConnection() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testing backend connection...')),
      );
      
      final uri = Uri.parse('http://localhost:3001/auth/config');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Backend is running'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Backend returned ${response.statusCode}'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
