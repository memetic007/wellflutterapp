import 'dart:convert';
import 'package:http/http.dart' as http;

class WellApiService {
  static const String baseUrl = 'http://localhost:5000';
  String? _sessionId;
  String? _username;
  String? _password;

  bool get isConnected => _sessionId != null;

  Future<Map<String, dynamic>> connect(String username, String password) async {
    try {
      // Store credentials for reconnection attempts
      _username = username;
      _password = password;

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

  // Helper method to attempt reconnection
  Future<bool> _attemptReconnection() async {
    if (_username == null || _password == null) {
      return false;
    }

    try {
      final result = await connect(_username!, _password!);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to execute HTTP requests with reconnection logic
  Future<Map<String, dynamic>> _executeWithReconnection({
    required Future<http.Response> Function() requestFn,
    required Map<String, dynamic> Function(Map<String, dynamic>)
        processResponseFn,
  }) async {
    try {
      // First attempt
      final response = await requestFn();

      // If unauthorized, try to reconnect
      if (response.statusCode == 401) {
        // First reconnection attempt
        bool reconnected = await _attemptReconnection();
        if (reconnected) {
          // Retry the original request
          final retryResponse = await requestFn();
          return processResponseFn(jsonDecode(retryResponse.body));
        }

        // Second reconnection attempt
        reconnected = await _attemptReconnection();
        if (reconnected) {
          // Retry the original request again
          final retryResponse = await requestFn();
          return processResponseFn(jsonDecode(retryResponse.body));
        }

        // Both reconnection attempts failed
        return {
          'success': false,
          'response': '',
          'error': 'Reconnection failed',
        };
      }

      // Process the response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return processResponseFn(responseData);
      } else {
        return {
          'success': false,
          'response': '',
          'error': 'Server error: ${response.statusCode}\n${response.body}',
        };
      }
    } catch (e) {
      // For network errors, try to reconnect
      try {
        // First reconnection attempt
        bool reconnected = await _attemptReconnection();
        if (reconnected) {
          // Retry the original request
          final retryResponse = await requestFn();
          return processResponseFn(jsonDecode(retryResponse.body));
        }

        // Second reconnection attempt
        reconnected = await _attemptReconnection();
        if (reconnected) {
          // Retry the original request again
          final retryResponse = await requestFn();
          return processResponseFn(jsonDecode(retryResponse.body));
        }

        // Both reconnection attempts failed
        return {
          'success': false,
          'response': '',
          'error': 'Reconnection failed',
        };
      } catch (reconnectError) {
        return {
          'success': false,
          'response': '',
          'error': 'Reconnection failed: $reconnectError',
        };
      }
    }
  }

  Future<Map<String, dynamic>> processCommand(Map<String, dynamic> data) async {
    return _executeWithReconnection(
      requestFn: () => http.post(
        Uri.parse('$baseUrl/extractconfcontent'),
        headers: _getHeaders(),
        body: jsonEncode({
          'command': data['command'],
          'conflist': data['conflist'] ?? false,
        }),
      ),
      processResponseFn: (responseData) => {
        'success': true,
        'response': responseData['output'] ?? '',
        'conflist': responseData['conflist'] ?? [],
        'error': responseData['error_output'] ?? '',
      },
    );
  }

  Future<Map<String, dynamic>> processText(String text,
      {String? source}) async {
    return _executeWithReconnection(
      requestFn: () => http.post(
        Uri.parse('$baseUrl/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source': source,
        }),
      ),
      processResponseFn: (responseData) => {
        'success': true,
        'response': responseData,
        'error': '',
      },
    );
  }

  Future<Map<String, dynamic>> postReply({
    required String content,
    required String conference,
    required String topic,
    bool hide = false,
    String? username,
  }) async {
    // Parse the topic handle to get the actual conference and topic number
    final parts = topic.split('.');
    if (parts.length >= 2) {
      // Take everything except the last part for conference
      conference = parts.sublist(0, parts.length - 1).join('.');
      // Take the last part as the topic number
      topic = parts.last;
    }

    // Convert content to base64
    final base64Content = base64.encode(utf8.encode(content));

    // Prepare request body
    final requestBody = {
      'base64_content': base64Content,
      'conference': conference,
      'topic': topic,
      'hide': hide,
    };

    // Add username if provided (needed for hide functionality)
    if (username != null) {
      requestBody['username'] = username;
    }

    return _executeWithReconnection(
      requestFn: () => http.post(
        Uri.parse('$baseUrl/postreply'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ),
      processResponseFn: (responseData) => {
        'success': true,
        'output': responseData['output'] ?? responseData['response'] ?? '',
        'error': '',
      },
    );
  }

  Future<Map<String, dynamic>> getCfList() async {
    return _executeWithReconnection(
      requestFn: () => http.get(
        Uri.parse('$baseUrl/cflist'),
        headers: _getHeaders(),
      ),
      processResponseFn: (data) => {
        'success': true,
        'cflist': data['cflist'],
      },
    );
  }

  Future<Map<String, dynamic>> putCfList(List<String> cflist) async {
    return _executeWithReconnection(
      requestFn: () => http.post(
        Uri.parse('$baseUrl/put_cflist'),
        headers: _getHeaders(),
        body: jsonEncode({
          'cflist': cflist,
        }),
      ),
      processResponseFn: (data) => {
        'success': true,
        'message': data['message'] ?? 'Successfully updated conference list',
      },
    );
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_sessionId != null) 'X-Session-ID': _sessionId!,
    };
  }
}
