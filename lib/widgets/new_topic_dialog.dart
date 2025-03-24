import 'package:flutter/material.dart';
import '../utils/credentials_manager.dart';
import 'text_editor_with_nav.dart';
import '../services/post_debug_service.dart';
import '../models/post_debug_entry.dart';
import '../services/well_api_service.dart';

class NewTopicDialog extends StatefulWidget {
  final String conference;
  final CredentialsManager credentialsManager;

  const NewTopicDialog({
    super.key,
    required this.conference,
    required this.credentialsManager,
  });

  @override
  State<NewTopicDialog> createState() => _NewTopicDialogState();
}

class _NewTopicDialogState extends State<NewTopicDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final WellApiService _apiService = WellApiService();
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Topic'),
      content: SizedBox(
        width: 640,
        height: _errorMessage.isNotEmpty ? 450 : 400,
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                      color: Colors.red.shade700,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'Enter topic title...',
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextEditorWithNav(
                controller: _contentController,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your topic content here...',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _handleSubmit(context),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    setState(() {
      _errorMessage = '';
      _isSubmitting = true;
    });

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text;

      // Validate title
      if (title.isEmpty) {
        throw Exception('Title cannot be empty');
      }

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

      // Get username for API call
      final username = await widget.credentialsManager.getUsername();

      // Send the new topic
      final result = await _apiService.postReply(
        content: content,
        conference: widget.conference,
        topic: '0', // Use 0 for new topics
        hide: false,
        username: username,
        option: 'newtopic',
        title: title,
      );

      // Record debug information
      final debugEntry = PostDebugEntry(
        timestamp: DateTime.now(),
        originalText: content,
        success: result['success'] ?? false,
        response: result['output'] ?? result['response'] ?? '',
        error: result['error'] ?? '',
      );
      PostDebugService().addDebugEntry(debugEntry);

      // Show result
      if (result['success'] == true) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Topic created successfully'),
            behavior: SnackBarBehavior.floating,
            width: MediaQuery.of(context).size.width * 0.3,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating topic: ${e.toString()}';
        _isSubmitting = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
