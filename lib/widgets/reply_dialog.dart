import 'package:flutter/material.dart';
import '../utils/credentials_manager.dart';
import 'text_editor_with_nav.dart';
import '../services/post_debug_service.dart';
import '../models/post_debug_entry.dart';
import '../services/well_api_service.dart';

class ReplyDialog extends StatefulWidget {
  final String title;
  final String conference;
  final String topicNumber;
  final CredentialsManager credentialsManager;
  final bool showOutputField;

  const ReplyDialog({
    super.key,
    required this.title,
    required this.conference,
    required this.topicNumber,
    required this.credentialsManager,
    this.showOutputField = false,
  });

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final WellApiService _apiService = WellApiService();
  bool _hideAfterPosting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 640,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: TextEditorWithNav(
                controller: _replyController,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your reply here...',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _hideAfterPosting,
                  onChanged: (value) {
                    setState(() {
                      _hideAfterPosting = value ?? false;
                    });
                  },
                ),
                const Text('Hide after posting'),
                const Spacer(),
              ],
            ),
            if (widget.showOutputField) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: TextField(
                  controller: _outputController,
                  maxLines: null,
                  readOnly: true,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Command output...',
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _handleSubmit(context),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    try {
      // Clear the debug output first if showing output field
      if (widget.showOutputField) {
        _outputController.clear();
      }

      final replyText = _replyController.text;

      // Ensure we have a connection first
      if (!_apiService.isConnected) {
        final username = await widget.credentialsManager.getUsername();
        final password = await widget.credentialsManager.getPassword();

        if (username == null || password == null) {
          throw Exception('Username or password not found');
        }

        final connectResult = await _apiService.connect(username, password);
        if (!connectResult['success']) {
          throw Exception('Failed to connect: ${connectResult['error']}');
        }
      }

      // Get username for hide functionality
      final username = await widget.credentialsManager.getUsername();

      // Send the reply
      final result = await _apiService.postReply(
        content: replyText,
        conference: widget.conference,
        topic: widget.topicNumber,
        hide: _hideAfterPosting,
        username: username,
      );

      // Add debug output if showing output field
      if (widget.showOutputField) {
        _outputController.text += 'Widget: ReplyDialog\n';
        _outputController.text +=
            '\nSending reply to: ${widget.conference}.${widget.topicNumber}\n';
        _outputController.text += 'Hide after posting: $_hideAfterPosting\n';

        if (result['output'].isNotEmpty) {
          _outputController.text += '\nResponse:\n${result['output']}\n';
        }
      }

      // Record debug information
      final debugEntry = PostDebugEntry(
        timestamp: DateTime.now(),
        originalText: replyText,
        success: result['success'] ?? false,
        response: result['output'] ?? '',
        error: result['error'] ?? '',
      );
      PostDebugService().addDebugEntry(debugEntry);

      // Show result
      if (result['success']) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reply sent successfully'),
            behavior: SnackBarBehavior.floating,
            width: MediaQuery.of(context).size.width * 0.3,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reply: $e'),
          behavior: SnackBarBehavior.floating,
          width: MediaQuery.of(context).size.width * 0.3,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
