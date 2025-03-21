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
      print('No stored credentials for reconnection');
      return false;
    }

    try {
      print('Attempting to reconnect with stored credentials');
      final result = await connect(_username!, _password!);
      final success = result['success'] == true;
      print('Reconnection result: $success');

      // Check if session ID was obtained
      if (success) {
        print('Reconnection successful, session ID obtained');
      } else {
        print('Reconnection failed: ${result['error']}');
      }

      return success;
    } catch (e) {
      print('Exception during reconnection attempt: $e');
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
      print('Executing HTTP request');
      // First attempt
      final response = await requestFn();
      print('Initial request status code: ${response.statusCode}');

      // Handle unauthorized error (401) - needs reconnection
      if (response.statusCode == 401) {
        print('Got 401 unauthorized, attempting first reconnection');

        // First reconnection attempt
        bool reconnected = await _attemptReconnection();
        print('First reconnection attempt result: $reconnected');

        if (reconnected) {
          // Retry the original request
          print('Retrying request after first successful reconnection');
          final retryResponse = await requestFn();
          print('Retry request status code: ${retryResponse.statusCode}');

          if (retryResponse.statusCode == 200) {
            return processResponseFn(jsonDecode(retryResponse.body));
          }
          // If still failing, try one more time
        }

        // Second reconnection attempt
        print('Attempting second reconnection');
        reconnected = await _attemptReconnection();
        print('Second reconnection attempt result: $reconnected');

        if (reconnected) {
          // Retry the original request again
          print('Retrying request after second successful reconnection');
          final retryResponse = await requestFn();
          print(
              'Second retry request status code: ${retryResponse.statusCode}');

          if (retryResponse.statusCode == 200) {
            return processResponseFn(jsonDecode(retryResponse.body));
          }
        }

        // Both reconnection attempts failed
        return {
          'success': false,
          'response': '',
          'error': 'Authentication failed after reconnection attempts',
        };
      }

      // Process the response for successful requests
      if (response.statusCode == 200) {
        print('Request successful with status code 200');
        final responseData = jsonDecode(response.body);
        return processResponseFn(responseData);
      } else {
        print('Request failed with status code: ${response.statusCode}');
        return {
          'success': false,
          'response': '',
          'error': 'Server error: ${response.statusCode}\n${response.body}',
        };
      }
    } catch (e) {
      print('Network or other error: $e');
      // For network errors, try to reconnect
      try {
        // First reconnection attempt
        print('Attempting reconnection after network error');
        bool reconnected = await _attemptReconnection();
        print('Reconnection attempt result: $reconnected');

        if (reconnected) {
          // Retry the original request
          print('Retrying request after reconnection');
          final retryResponse = await requestFn();
          print('Retry request status code: ${retryResponse.statusCode}');

          if (retryResponse.statusCode == 200) {
            return processResponseFn(jsonDecode(retryResponse.body));
          }
        }

        // Second reconnection attempt
        print('Attempting second reconnection after network error');
        reconnected = await _attemptReconnection();
        print('Second reconnection attempt result: $reconnected');

        if (reconnected) {
          // Retry the original request again
          print('Retrying request after second reconnection');
          final retryResponse = await requestFn();
          print(
              'Second retry request status code: ${retryResponse.statusCode}');

          if (retryResponse.statusCode == 200) {
            return processResponseFn(jsonDecode(retryResponse.body));
          }
        }

        // Both reconnection attempts failed
        return {
          'success': false,
          'response': '',
          'error': 'Connection failed after reconnection attempts',
        };
      } catch (reconnectError) {
        print('Error during reconnection attempt: $reconnectError');
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

  Future<Map<String, dynamic>> _forgetOrRememberTopic({
    required String conference,
    required String topic,
    required String option,
  }) async {
    print('Attempting to $option topic: $conference.$topic');

    // Parse the topic handle if it contains the conference
    final parts = topic.split('.');
    String topicNumber;
    if (parts.length >= 2 && parts[0] == conference) {
      // If topic is in format "conference.number", extract just the number part
      topicNumber = parts.last;
    } else {
      // Otherwise, use the topic as is
      topicNumber = topic;
    }

    return _executeWithReconnection(
      requestFn: () => http.post(
        Uri.parse('$baseUrl/forget_remember'),
        headers: _getHeaders(),
        body: jsonEncode({
          'conference': conference,
          'topic': topicNumber,
          'option': option,
        }),
      ),
      processResponseFn: (responseData) => {
        'success': responseData['success'] ?? false,
        'message': responseData['message'] ?? 'Topic ${option}ed',
        'error': responseData['error'] ?? '',
      },
    );
  }

  Future<Map<String, dynamic>> forgetTopic({
    required String conference,
    required String topic,
  }) async {
    return _forgetOrRememberTopic(
      conference: conference,
      topic: topic,
      option: 'forget',
    );
  }

  Future<Map<String, dynamic>> rememberTopic({
    required String conference,
    required String topic,
  }) async {
    return _forgetOrRememberTopic(
      conference: conference,
      topic: topic,
      option: 'remember',
    );
  }

  Future<Map<String, dynamic>> disconnect() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/disconnect'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _sessionId = null;
        _username = null;
        _password = null;
        return {
          'success': true,
          'message': 'Disconnected successfully',
          'error': '',
        };
      } else {
        return {
          'success': false,
          'message': '',
          'error':
              'Failed to disconnect: ${response.statusCode}\n${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '',
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
