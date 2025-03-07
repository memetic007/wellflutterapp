import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topic.dart';
import 'post_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math' as math;
import 'text_editor_with_nav.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/credentials_manager.dart';
import '../models/post_debug_entry.dart';
import '../services/post_debug_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopicPostsContainer extends StatefulWidget {
  final List<Topic> topics;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onForgetPressed;

  const TopicPostsContainer({
    super.key,
    required this.topics,
    this.onPrevious,
    this.onNext,
    this.onForgetPressed,
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
  final CredentialsManager credentialsManager = CredentialsManager();

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
                  ...topic.posts.map((post) => PostWidget(post: post)).toList(),
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${topic.handle}'),
        content: SizedBox(
          width: 640,
          height: 400,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Get the text and convert to base64
                final replyText = _replyController.text;
                final replyContent = base64.encode(utf8.encode(replyText));

                // Get credentials
                final username = await credentialsManager.getUsername();
                final password = await credentialsManager.getPassword();

                if (username == null || password == null) {
                  throw Exception('Username or password not found');
                }

                // Hard-code values for testing
                final conf = "freefire.ind";
                final topicNum = "19";

                // Get current directory from shared preferences
                final prefs = await SharedPreferences.getInstance();
                final currentDirectory = prefs.getString('last_directory') ?? '';
                
                if (currentDirectory.isEmpty) {
                  throw Exception('Directory is not set');
                }

                // Build the new command format
                final command = 'cd "$currentDirectory" ; python post.py -debug --username $username --password $password --conf $conf --topic $topicNum $replyContent';

                // Create debug info string (but don't display it)
                final debugInfo = 'Widget: TopicPostsContainer\n'
                    'Executing command in directory: $currentDirectory\n'
                    'Command:\n$command\n';

                // Execute via powershell
                final process = await Process.run(
                  'powershell.exe',
                  ['-Command', command],
                  runInShell: true,
                );

                // Record post debug information with widget info
                PostDebugService().addEntry(
                  PostDebugEntry(
                    timestamp: DateTime.now(),
                    command: command,
                    response: process.stdout.toString(),
                    stderr: process.stderr.toString(),
                    originalText: replyText,
                    success: process.exitCode == 0,
                    widgetSource: 'TopicPostsContainer', // Add widget source
                  ),
                );

                // Show result
                if (process.exitCode == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reply submitted successfully'),
                      behavior: SnackBarBehavior.floating,
                      width: MediaQuery.of(context).size.width * 0.3,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  throw Exception(process.stderr.toString());
                }
                
                Navigator.of(context).pop();
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
