import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topic.dart';
import 'post_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import '../utils/credentials_manager.dart';

class TopicPostsContainer extends StatefulWidget {
  final List<Topic> topics;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onForgetPressed;
  final TextEditingController? debugController;
  final CredentialsManager credentialsManager;
  final String directory;

  const TopicPostsContainer({
    super.key,
    required this.topics,
    this.onPrevious,
    this.onNext,
    this.onForgetPressed,
    this.debugController,
    required this.credentialsManager,
    required this.directory,
  });

  @override
  State<TopicPostsContainer> createState() => TopicPostsContainerState();
}

class TopicPostsContainerState extends State<TopicPostsContainer> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final FocusNode _focusNode = FocusNode();
  int _currentIndex = 0;
  bool _isScrolling = false;
  final Map<int, bool> _forgetStates = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _itemPositionsListener.itemPositions.addListener(_updateCurrentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(TopicPostsContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset position when topics list changes
    if (widget.topics != oldWidget.topics) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  void _updateCurrentIndex() {
    final positions = _itemPositionsListener.itemPositions.value.toList();
    if (positions.isEmpty) return;

    positions.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topItem = positions.first;

    if (topItem.index != _currentIndex) {
      setState(() {
        _currentIndex = topItem.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topics.isEmpty) {
      return const Center(child: Text('No topics available'));
    }

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            // Scroll by approximately one line of text (about 24 pixels)
            _itemScrollController.scrollTo(
              index: _currentIndex,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              alignment: _getNextAlignment(-24.0),
            );
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            // Scroll up by one line
            _itemScrollController.scrollTo(
              index: _currentIndex,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              alignment: _getNextAlignment(24.0),
            );
          } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
            // Keep larger jump for page up/down
            final newIndex =
                math.min(_currentIndex + 5, widget.topics.length - 1);
            scrollToIndex(newIndex);
          } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
            // Keep larger jump for page up/down
            final newIndex = math.max(_currentIndex - 5, 0);
            scrollToIndex(newIndex);
          } else if (event.logicalKey == LogicalKeyboardKey.home) {
            scrollToIndex(0);
          } else if (event.logicalKey == LogicalKeyboardKey.end) {
            scrollToIndex(widget.topics.length - 1, alignment: 1.0);
          }
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ScrollablePositionedList.builder(
            itemCount: widget.topics.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemBuilder: (context, index) {
              final topic = widget.topics[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[400]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${topic.handle} - ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text: topic.title,
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
                              value: _forgetStates[index] ?? false,
                              onChanged: (bool? value) {
                                setState(() {
                                  _forgetStates[index] = value ?? false;
                                });
                                if (value == true &&
                                    widget.onForgetPressed != null) {
                                  widget.onForgetPressed!();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...topic.posts.map((post) => PostWidget(
                    post: post,
                  )).toList(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.reply),
                      label: const Text('Reply'),
                      onPressed: () => _showReplyDialog(context, topic),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void scrollToNext() {
    if (_currentIndex >= widget.topics.length - 1 || _isScrolling) return;
    setState(() {
      _isScrolling = true;
    });
    _itemScrollController
        .scrollTo(
      index: _currentIndex + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      widget.onNext?.call();
      setState(() {
        _isScrolling = false;
      });
    });
  }

  void scrollToPrevious() {
    if (_currentIndex <= 0 || _isScrolling) return;
    setState(() {
      _isScrolling = true;
    });
    _itemScrollController
        .scrollTo(
      index: _currentIndex - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      widget.onPrevious?.call();
      setState(() {
        _isScrolling = false;
      });
    });
  }

  void scrollToIndex(int index, {double alignment = 0.0}) {
    if (index < 0 || index >= widget.topics.length || _isScrolling) return;
    setState(() {
      _isScrolling = true;
    });
    _itemScrollController
        .scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: alignment,
    )
        .then((_) {
      setState(() {
        _isScrolling = false;
      });
    });
  }

  String get currentPositionText {
    final total = widget.topics.length;
    // Always show position 1 if we have topics but no current index yet
    if (total > 0 && _currentIndex == 0) {
      return 'Topic 1 of $total';
    }
    return 'Topic ${total > 0 ? _currentIndex + 1 : 0} of $total';
  }

  bool get isScrolling => _isScrolling;

  // Add method to reset position
  void resetToStart() {
    setState(() {
      _currentIndex = 0;
    });
    if (widget.topics.isNotEmpty) {
      scrollToIndex(0);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_updateCurrentIndex);
    super.dispose();
  }

  double _getNextAlignment(double offset) {
    final positions = _itemPositionsListener.itemPositions.value.toList();
    if (positions.isEmpty) return 0.0;

    positions.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final currentPosition = positions.first;

    // Calculate new alignment based on current position and desired offset
    return currentPosition.itemLeadingEdge +
        (offset / 500.0); // 500.0 is approximate viewport height
  }

  void _showReplyDialog(BuildContext context, Topic topic) {
    final TextEditingController _replyController = TextEditingController();
    final TextEditingController _outputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${topic.handle}'),
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
                  _handleTextNavigation(LogicalKeyboardKey.arrowLeft, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad6) {
                  _handleTextNavigation(LogicalKeyboardKey.arrowRight, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad8) {
                  _handleTextNavigation(LogicalKeyboardKey.arrowUp, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad2) {
                  _handleTextNavigation(LogicalKeyboardKey.arrowDown, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad7) {
                  _handleTextNavigation(LogicalKeyboardKey.home, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad1) {
                  _handleTextNavigation(LogicalKeyboardKey.end, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad9) {
                  _handleTextNavigation(LogicalKeyboardKey.pageUp, _replyController);
                } else if (event.physicalKey == PhysicalKeyboardKey.numpad3) {
                  _handleTextNavigation(LogicalKeyboardKey.pageDown, _replyController);
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
                _outputController.text += '\nCommand output:\n${process.stdout}\n';
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

  void _handleTextNavigation(LogicalKeyboardKey key, TextEditingController controller) {
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
          // If first line is empty (starts with newline), just move to start
          if (text.isNotEmpty && text[0] == '\n') {
            controller.selection = const TextSelection.collapsed(offset: 0);
            break;
          }
          // Otherwise preserve column position in first line
          final firstLineEnd = text.indexOf('\n');
          final firstLineLength = firstLineEnd == -1 ? text.length : firstLineEnd;
          final newOffset = math.min(column, firstLineLength);
          controller.selection = TextSelection.collapsed(offset: math.max(0, newOffset));
          break;
        }

        // Check if previous line is empty
        if (lineStart - prevLineStart == 1) {
          // Previous line is empty, move to its start
          controller.selection = TextSelection.collapsed(offset: prevLineStart + 1);
          break;
        }

        // Normal column preservation for non-empty lines
        final prevLineLength = lineStart - (prevLineStart + 1);
        final newOffset = (prevLineStart + 1 + math.min(column, prevLineLength)).toInt();
        controller.selection = TextSelection.collapsed(offset: math.max(0, newOffset));
        break;
      case LogicalKeyboardKey.arrowDown:
        final lineStart = text.lastIndexOf('\n', selection.start);
        final nextLineStart = text.indexOf('\n', selection.start);
        
        // Handle last line case
        if (nextLineStart == -1) {
          controller.selection = TextSelection.collapsed(offset: text.length);
          break;
        }

        // Get current column position
        final currentLineStart = lineStart == -1 ? 0 : lineStart + 1;
        
        // If we're on an empty line, just move to next line start
        if (selection.start == currentLineStart) {
          controller.selection = TextSelection.collapsed(offset: nextLineStart + 1);
          break;
        }
        
        // Normal column preservation behavior
        final column = selection.start - currentLineStart;
        final nextLineEnd = text.indexOf('\n', nextLineStart + 1);
        final nextLineLength = nextLineEnd == -1 
            ? text.length - (nextLineStart + 1)
            : nextLineEnd - (nextLineStart + 1);
        
        final newOffset = (nextLineStart + 1 + math.min(column, nextLineLength)).toInt();
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
