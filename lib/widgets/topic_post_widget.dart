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
import 'reply_dialog.dart';

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...widget.topic.posts.map((post) => PostWidget(
                                    post: post,
                                  )),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors
                                      .grey[300], // Slightly darker background
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[400]!),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left: Topic Handle
                                    Text(
                                      widget.topic.handle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    // Center: Reply Button
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.reply),
                                      label: const Text('Reply'),
                                      onPressed: () =>
                                          _showReplyDialog(context),
                                    ),
                                    // Right: Forget Checkbox
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
                                                widget.onForgetPressed !=
                                                    null) {
                                              print('DEBUG - TopicPostWidget:');
                                              print(
                                                  '  - Topic title: "${widget.topic.title}"');
                                              print(
                                                  '  - Topic handle: "${widget.topic.handle}"');
                                              print(
                                                  '  - Full topic: ${widget.topic}');
                                              widget.onForgetPressed!();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => ReplyDialog(
        title: 'Reply to ${widget.topic.handle}',
        conference: widget.topic.conf,
        topicNumber: widget.topic.number.toString(),
        credentialsManager: widget.credentialsManager,
        showOutputField: false,
      ),
    );
  }
}
