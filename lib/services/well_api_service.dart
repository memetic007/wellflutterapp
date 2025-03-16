import 'dart:convert';
import 'package:http/http.dart' as http;

class WellApiService {
  static const String baseUrl = 'http://localhost:5000';
  String? _sessionId;

  bool get isConnected => _sessionId != null;

  Future<Map<String, dynamic>> connect(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];
        return {
          'success': true,
          'response': data,
          'error': '',
        };
      } else {
        return {
          'success': false,
          'response': '',
          'error':
              'Connection failed: ${response.statusCode}\n${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'response': '',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> processCommand(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/extractconfcontent'),
        headers: _getHeaders(),
        body: jsonEncode({
          'command': data['command'],
          'conflist': data['conflist'] ?? false,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'response': responseData['output'] ?? '',
          'conflist': responseData['conflist'] ?? [],
          'error': responseData['error_output'] ?? '',
        };
      } else {
        return {
          'success': false,
          'response': '',
          'conflist': [],
          'error': 'Server error: ${response.statusCode}\n${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'response': '',
        'conflist': [],
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> processText(String text,
      {String? source}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source': source,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'response': jsonDecode(response.body),
          'error': '',
        };
      } else {
        return {
          'success': false,
          'response': '',
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'response': '',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> postReply({
    required String content,
    required String conference,
    required String topic,
  }) async {
    try {
      if (_sessionId == null) {
        return {
          'success': false,
          'output': '',
          'error': 'No active session. Please connect first.',
        };
      }

      // Parse the topic handle to get the actual conference and topic number
      final parts = topic.split('.');
      if (parts.length >= 2) {
        conference = parts[0];
        topic = parts[1];
      }

      // Convert content to base64
      final base64Content = base64.encode(utf8.encode(content));

      // Log the request for debugging
      print('Sending request to /postreply:');
      print('  Conference: $conference');
      print('  Topic: $topic');
      print('  Session ID: $_sessionId');

      final response = await http.post(
        Uri.parse('$baseUrl/postreply'),
        headers: _getHeaders(),
        body: jsonEncode({
          'base64_content': base64Content,
          'conference': conference,
          'topic': topic,
        }),
      );

      // Log the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'output': responseData['output'] ?? responseData['response'] ?? '',
          'error': '',
        };
      } else if (response.statusCode == 401) {
        _sessionId = null;
        return {
          'success': false,
          'output': '',
          'error': 'Session expired. Please reconnect.',
        };
      } else {
        return {
          'success': false,
          'output': '',
          'error': 'Server error: ${response.statusCode}\n${response.body}',
        };
      }
    } catch (e) {
      print('Error in postReply: $e');
      return {
        'success': false,
        'output': '',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getCfList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cflist'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cflist': data['cflist'],
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> putCfList(List<String> cflist) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/put_cflist'),
        headers: _getHeaders(),
        body: jsonEncode({
          'cflist': cflist,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Successfully updated conference list',
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_sessionId != null) 'X-Session-ID': _sessionId!,
    };
  }
}
