import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topic.dart';
import 'post_widget.dart';
import 'dart:io';
import '../utils/credentials_manager.dart';
import 'dart:convert';
import 'dart:math' as math;

class TopicPostWidget extends StatefulWidget {
  final Topic topic;
  final VoidCallback? onForgetPressed;
  final String directory;
  final CredentialsManager credentialsManager;
  final TextEditingController? debugController;

  const TopicPostWidget({
    super.key,
    required this.topic,
    required this.directory,
    required this.credentialsManager,
    this.onForgetPressed,
    this.debugController,
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
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent) {
                // Handle tab key
                if (event.logicalKey == LogicalKeyboardKey.tab) {
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

                // Handle numpad navigation
                if (event.physicalKey == PhysicalKeyboardKey.numpad4) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.arrowLeft, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad6) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.arrowRight, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad8) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.arrowUp, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad2) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.arrowDown, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad7) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.home, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad1) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.end, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad9) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.pageUp, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad3) {
                  _handleTextNavigation(
                      LogicalKeyboardKey.pageDown, _replyController);
                }
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

                if (widget.debugController != null) {
                  widget.debugController!.text = _outputController.text;
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

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post Debug Output',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_outputController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTextNavigation(
      LogicalKeyboardKey key, TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        if (selection.start > 0) {
          controller.selection = TextSelection.collapsed(
            offset: selection.start - 1,
          );
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (selection.start < text.length) {
          controller.selection = TextSelection.collapsed(
            offset: selection.start + 1,
          );
        }
        break;
      case LogicalKeyboardKey.arrowUp:
        // Handle empty text or cursor at start
        if (text.isEmpty || selection.start == 0) {
          controller.selection = const TextSelection.collapsed(offset: 0);
          break;
        }

        // Find the start of the current line
        final lineStart = text.lastIndexOf('\n', selection.start - 1);
        if (lineStart == -1) {
          // We're on the first line, just move to start
          controller.selection = const TextSelection.collapsed(offset: 0);
          break;
        }

        final prevLineStart = text.lastIndexOf('\n', lineStart - 1);
        // Calculate column position, handling first line case
        final currentLineStart = lineStart + 1;
        final column = selection.start - currentLineStart;

        // Handle case when moving to first line
        if (prevLineStart == -1) {
          // Find first line length, handling case where there's no newline
          final firstNewline = text.indexOf('\n');
          final firstLineLength =
              firstNewline == -1 ? text.length : firstNewline;
          final newOffset = math.min(column, firstLineLength);
          controller.selection =
              TextSelection.collapsed(offset: math.max(0, newOffset));
          break;
        }

        final prevLineLength = lineStart - (prevLineStart + 1);
        final newOffset =
            (prevLineStart + 1 + math.min(column, prevLineLength)).toInt();
        controller.selection =
            TextSelection.collapsed(offset: math.max(0, newOffset));
        break;
      case LogicalKeyboardKey.arrowDown:
        final lineStart = text.lastIndexOf('\n', selection.start);
        final nextLineStart = text.indexOf('\n', selection.start);
        if (nextLineStart == -1) {
          // We're on the last line, move to end
          controller.selection = TextSelection.collapsed(offset: text.length);
          break;
        }
        final column = selection.start - (lineStart + 1);
        final nextLineEnd = text.indexOf('\n', nextLineStart + 1);
        final nextLineLength = nextLineEnd == -1
            ? text.length - (nextLineStart + 1)
            : nextLineEnd - (nextLineStart + 1);
        final newOffset =
            (nextLineStart + 1 + math.min(column, nextLineLength)).toInt();
        controller.selection = TextSelection.collapsed(offset: newOffset);
        break;
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.pageDown:
        final linesPerPage = 10;
        final direction = key == LogicalKeyboardKey.pageUp ? -1 : 1;
        var currentPos = selection.start;
        var remainingLines = linesPerPage;

        while (remainingLines > 0) {
          if (direction == -1) {
            final lineStart = text.lastIndexOf('\n', currentPos - 1);
            if (lineStart == -1) {
              currentPos = 0;
              break;
            }
            currentPos = lineStart + 1;
          } else {
            final nextLineStart = text.indexOf('\n', currentPos);
            if (nextLineStart == -1) {
              currentPos = text.length;
              break;
            }
            currentPos = nextLineStart + 1;
          }
          remainingLines--;
        }
        controller.selection = TextSelection.collapsed(offset: currentPos);
        break;
      case LogicalKeyboardKey.home:
        controller.selection = const TextSelection.collapsed(offset: 0);
        break;
      case LogicalKeyboardKey.end:
        controller.selection = TextSelection.collapsed(
          offset: text.length,
        );
        break;
      default:
        break;
    }
  }
}
