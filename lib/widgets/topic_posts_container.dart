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
import '../services/well_api_service.dart';
import 'reply_dialog.dart';

class TopicPostsContainer extends StatefulWidget {
  final List<Topic> topics;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onForgetPressed;
  final CredentialsManager credentialsManager;

  const TopicPostsContainer({
    super.key,
    required this.topics,
    this.onPrevious,
    this.onNext,
    this.onForgetPressed,
    required this.credentialsManager,
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
  final WellApiService _apiService = WellApiService();

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

  void _showReplyDialog(BuildContext parentContext, Topic topic) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => ReplyDialog(
        title: 'Reply to ${topic.handle}',
        conference: 'test', // Use test conference for now
        topicNumber: '2264', // Use test topic for now
        credentialsManager: widget.credentialsManager,
        showOutputField: false, // Match original implementation
      ),
    );
  }
}
