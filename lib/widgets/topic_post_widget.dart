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
  final bool isWatched;
  final Function(bool) onWatchChanged;

  const TopicPostWidget({
    super.key,
    required this.topic,
    required this.credentialsManager,
    this.onForgetPressed,
    required this.isWatched,
    required this.onWatchChanged,
  });

  @override
  State<TopicPostWidget> createState() => _TopicPostWidgetState();
}

class _TopicPostWidgetState extends State<TopicPostWidget> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isForgetChecked = false;
  bool _isWatched = false;
  final TextEditingController _outputController = TextEditingController();
  late WellApiService _apiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _apiService = WellApiService();
    _isWatched = widget.isWatched;
  }

  @override
  void didUpdateWidget(TopicPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWatched != widget.isWatched) {
      _isWatched = widget.isWatched;
    }
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

  void _handleForgetChecked(bool? value) async {
    setState(() {
      _isForgetChecked = value ?? false;
    });

    try {
      // Get conference name and topic from handle
      final parts = widget.topic.handle.split('.');
      final conference = parts.length > 1
          ? parts.sublist(0, parts.length - 1).join('.')
          : widget.topic.handle;
      final topicNumber = parts.length > 1 ? parts.last : widget.topic.handle;

      // Ensure we have a connection
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

      // Call the appropriate API based on checkbox state
      final result = value == true
          ? await _apiService.forgetTopic(
              conference: conference,
              topic: topicNumber,
            )
          : await _apiService.rememberTopic(
              conference: conference,
              topic: topicNumber,
            );

      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Topic ${value == true ? "forgotten" : "remembered"}: ${widget.topic.handle}'),
              behavior: SnackBarBehavior.floating,
              width: MediaQuery.of(context).size.width * 0.3,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Call the onForgetPressed callback if provided
        if (widget.onForgetPressed != null) {
          widget.onForgetPressed!();
        }
      } else {
        throw Exception(result['error'] ??
            'Failed to ${value == true ? "forget" : "remember"} topic');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isForgetChecked = value == true; // Reset checkbox to previous state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${value == true ? "forgetting" : "remembering"} topic: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            width: MediaQuery.of(context).size.width * 0.3,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleWatchChanged(bool? value) {
    setState(() {
      _isWatched = value ?? false;
    });
    widget.onWatchChanged(_isWatched);
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
                            child: SelectableText.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.topic.handle} ',
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
                              const Text('Watch'),
                              Checkbox(
                                value: _isWatched,
                                onChanged: _handleWatchChanged,
                              ),
                              const Text('Forget'),
                              Checkbox(
                                value: _isForgetChecked,
                                onChanged: _handleForgetChecked,
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
                              Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                elevation: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFFF5F5F5), // Very light neutral grey, just slightly darker than Card
                                    borderRadius: BorderRadius.circular(4.0),
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
                                      // Right: Watch and Forget Checkboxes
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Watch'),
                                          Checkbox(
                                            value: _isWatched,
                                            onChanged: _handleWatchChanged,
                                          ),
                                          const Text('Forget'),
                                          Checkbox(
                                            value: _isForgetChecked,
                                            onChanged: _handleForgetChecked,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
        title: 'Reply to ${widget.topic.handle}\n${widget.topic.title}',
        conference: widget.topic.handle,
        topicNumber: widget.topic.handle,
        credentialsManager: widget.credentialsManager,
        showOutputField: false,
      ),
    );
  }
}
