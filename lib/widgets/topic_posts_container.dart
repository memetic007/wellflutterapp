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
import 'topic_post_widget.dart';

class TopicPostsContainer extends StatefulWidget {
  final List<Topic> topics;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onForgetPressed;
  final CredentialsManager credentialsManager;
  final bool Function(Topic) isTopicWatched;
  final Function(Topic, bool) onWatchChanged;

  const TopicPostsContainer({
    super.key,
    required this.topics,
    this.onPrevious,
    this.onNext,
    this.onForgetPressed,
    required this.credentialsManager,
    required this.isTopicWatched,
    required this.onWatchChanged,
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

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
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
                children: [
                  // Topic header with title and Watch/Forget checkboxes
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${topic.handle} ',
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
                            const Text('Watch'),
                            Checkbox(
                              value: widget.isTopicWatched(topic),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onWatchChanged(topic, value);
                                }
                              },
                            ),
                            const Text('Forget'),
                            Checkbox(
                              value: !widget.isTopicWatched(topic),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onWatchChanged(topic, !value);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Posts list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topic.posts.length,
                    itemBuilder: (context, index) {
                      final post = topic.posts[index];
                      return PostWidget(post: post);
                    },
                  ),
                  // Bottom bar with Reply button and Watch/Forget checkboxes
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Handle on the left
                        Text(
                          topic.handle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        // Centered Reply button
                        Expanded(
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => _showReplyDialog(context, topic),
                              icon: const Icon(Icons.reply, size: 16),
                              label: const Text('Reply'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                        ),
                        // Watch/Forget checkboxes on the right
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Watch'),
                            Checkbox(
                              value: widget.isTopicWatched(topic),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onWatchChanged(topic, value);
                                }
                              },
                            ),
                            const Text('Forget'),
                            Checkbox(
                              value: !widget.isTopicWatched(topic),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onWatchChanged(topic, !value);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Spacing between topics
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
    showDialog(
      context: context,
      builder: (dialogContext) => ReplyDialog(
        title: 'Reply to ${topic.handle}',
        conference: topic.handle,
        topicNumber: topic.handle,
        credentialsManager: widget.credentialsManager,
        showOutputField: false,
      ),
    );
  }

  Future<void> _handleForgetChecked(bool? value, int index, Topic topic) async {
    setState(() {
      _forgetStates[index] = value ?? false;
    });

    try {
      // Get conference name and topic from handle
      final parts = topic.handle.split('.');
      final conference = parts.length > 1
          ? parts.sublist(0, parts.length - 1).join('.')
          : topic.handle;
      final topicNumber = parts.length > 1 ? parts.last : topic.handle;

      print(
          '${value == true ? "Forgetting" : "Remembering"} topic: Conference=$conference, Topic=$topicNumber');

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
                  'Topic ${value == true ? "forgotten" : "remembered"}: ${topic.handle}'),
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
      print('Error ${value == true ? "forgetting" : "remembering"} topic: $e');
      if (mounted) {
        setState(() {
          _forgetStates[index] =
              value == true; // Reset checkbox to previous state
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
}
