import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topic.dart';
import 'post_widget.dart';
import 'dart:io';
import '../utils/credentials_manager.dart';
import 'text_editor_with_nav.dart';
import '../services/post_debug_service.dart';
import '../models/post_debug_entry.dart';
import 'dart:convert';
import '../services/well_api_service.dart';

class TopicPostWidget extends StatefulWidget {
  final Topic topic;
  final VoidCallback? onForgetPressed;
  final CredentialsManager credentialsManager;

  const TopicPostWidget({
    super.key,
    required this.topic,
    required this.credentialsManager,
    this.onForgetPressed,
  });

  @override
  State<TopicPostWidget> createState() => _TopicPostWidgetState();
}

class _TopicPostWidgetState extends State<TopicPostWidget> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isForgetChecked = false;
  final TextEditingController _outputController = TextEditingController();
  late WellApiService _apiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _apiService = WellApiService();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Scroll by approximately one line of text
        _scrollController.animateTo(
          (_scrollController.offset + 24.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Scroll up by one line
        _scrollController.animateTo(
          (_scrollController.offset - 24.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        _scrollController.animateTo(
          (_scrollController.offset + 300.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        _scrollController.animateTo(
          (_scrollController.offset - 300.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[400]!)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '[${widget.topic.handle}] ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.topic.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Forget'),
                              Checkbox(
                                value: _isForgetChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isForgetChecked = value ?? false;
                                  });
                                  if (value == true &&
                                      widget.onForgetPressed != null) {
                                    print('DEBUG - TopicPostWidget:');
                                    print(
                                        '  - Topic title: "${widget.topic.title}"');
                                    print(
                                        '  - Topic handle: "${widget.topic.handle}"');
                                    print('  - Full topic: ${widget.topic}');
                                    widget.onForgetPressed!();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        interactive: true,
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              ...widget.topic.posts
                                  .map((post) => PostWidget(post: post))
                                  .toList(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.reply),
                                  label: const Text('Reply'),
                                  onPressed: () => _showReplyDialog(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext parentContext) {
    final TextEditingController _replyController = TextEditingController();
    final TextEditingController _outputController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reply to ${widget.topic.handle}'),
        content: SizedBox(
          width: 640,
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Clear the debug output first
                _outputController.clear();

                final replyText = _replyController.text;

                // Ensure we have a connection first
                if (!_apiService.isConnected) {
                  final username =
                      await widget.credentialsManager.getUsername();
                  final password =
                      await widget.credentialsManager.getPassword();

                  if (username == null || password == null) {
                    throw Exception('Username or password not found');
                  }

                  final connectResult =
                      await _apiService.connect(username, password);
                  if (!connectResult['success']) {
                    throw Exception(
                        'Failed to connect: ${connectResult['error']}');
                  }
                }

                // Send the reply
                final result = await _apiService.postReply(
                  content: replyText,
                  conference: widget.topic.conf,
                  topic: widget.topic.number.toString(),
                );

                // Add debug output
                _outputController.text += 'Widget: TopicPostWidget\n';
                _outputController.text +=
                    '\nSending reply to: ${widget.topic.conf}.${widget.topic.number}\n';

                if (result['output'].isNotEmpty) {
                  _outputController.text +=
                      '\nResponse:\n${result['output']}\n';
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
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: const Text('Reply sent successfully'),
                      behavior: SnackBarBehavior.floating,
                      width: MediaQuery.of(parentContext).size.width * 0.3,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  throw Exception(result['error']);
                }
              } catch (e) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Error sending reply: $e'),
                    behavior: SnackBarBehavior.floating,
                    width: MediaQuery.of(parentContext).size.width * 0.3,
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
