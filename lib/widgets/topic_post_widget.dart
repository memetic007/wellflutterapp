import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topic.dart';
import 'post_widget.dart';
import 'dart:io';
import '../utils/credentials_manager.dart';
import 'dart:convert';

class TopicPostWidget extends StatefulWidget {
  final Topic topic;
  final VoidCallback? onForgetPressed;
  final String directory;
  final CredentialsManager credentialsManager;

  const TopicPostWidget({
    super.key,
    required this.topic,
    required this.directory,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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

  void _showReplyDialog(BuildContext context) {
    final TextEditingController _replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${widget.topic.handle}'),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.tab) {
                    _replyController.value = TextEditingValue(
                      text: _replyController.text.replaceRange(
                        _replyController.selection.start,
                        _replyController.selection.end,
                        '    ',
                      ),
                      selection: TextSelection.collapsed(
                        offset: _replyController.selection.start + 4,
                      ),
                    );
                    return null;
                  }
                  return null;
                },
                child: Focus(
                  onKey: (node, event) {
                    if (event.logicalKey == LogicalKeyboardKey.tab) {
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _replyController,
                    maxLines: 8,
                    style: const TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type your reply here...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onEditingComplete: () {},
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onTap: () {
                      FocusScope.of(context).requestFocus();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _outputController,
                maxLines: 10,
                readOnly: true,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Command output...',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Clear the debug output first
                _outputController.clear();

                // Get credentials
                final username = await widget.credentialsManager.getUsername();
                final password = await widget.credentialsManager.getPassword();

                if (username == null || password == null) {
                  throw Exception('Username or password not found');
                }

                final currentDirectory = widget.directory.trim();
                if (currentDirectory.isEmpty) {
                  throw Exception('Directory is empty');
                }

                // Get the raw text and convert to base64
                final bytes = utf8.encode(_replyController.text);
                final base64Content = base64.encode(bytes);

                // Build the simple command
                final command =
                    'cd "$currentDirectory" ; python post.py --username $username --password $password $base64Content';

                // Add to debug output
                _outputController.text +=
                    '\nExecuting command in directory: $currentDirectory\n';
                _outputController.text += 'Command:\n$command\n';

                // Execute via powershell
                final process = await Process.run(
                  'powershell.exe',
                  ['-Command', command],
                  runInShell: true,
                );

                // Add command output to debug
                _outputController.text +=
                    '\nCommand output:\n${process.stdout}\n';
                if (process.stderr.toString().isNotEmpty) {
                  _outputController.text += '\nErrors:\n${process.stderr}\n';
                }

                // Add the original post text
                _outputController.text +=
                    '\nOriginal post text:\n${_replyController.text}\n';

                // Show result
                if (process.exitCode == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reply sent successfully'),
                      behavior: SnackBarBehavior.floating,
                      width: MediaQuery.of(context).size.width * 0.3,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  throw Exception(process.stderr.toString());
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
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
