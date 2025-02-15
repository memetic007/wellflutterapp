import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'post_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  int _currentIndex = 0;
  bool _isScrolling = false;
  final Map<int, bool> _forgetStates = {}; // Track forget state for each topic

  @override
  void initState() {
    super.initState();
    _currentIndex = 0; // Ensure we start at index 0
    _itemPositionsListener.itemPositions.addListener(_updateCurrentIndex);
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

    // Sort positions by leading edge to find the topmost
    positions.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topItem = positions.first;

    // Only update if it's actually changed
    if (topItem.index != _currentIndex) {
      setState(() {
        _currentIndex = topItem.index;
      });

      // Notify parent of index change during manual scroll
      if (!_isScrolling) {
        // Only during manual scroll
        if (_currentIndex > topItem.index) {
          widget.onPrevious?.call();
        } else {
          widget.onNext?.call();
        }
      }
    }
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
      alignment: 0.0,
    )
        .then((_) {
      widget.onNext?.call();
      _updateCurrentIndex();
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
      alignment: 0.0,
    )
        .then((_) {
      widget.onPrevious?.call();
      _updateCurrentIndex();
      setState(() {
        _isScrolling = false;
      });
    });
  }

  void scrollToIndex(int index) {
    if (index < 0 || index >= widget.topics.length || _isScrolling) return;

    setState(() {
      _isScrolling = true;
    });

    _itemScrollController
        .scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.0,
    )
        .then((_) {
      _updateCurrentIndex();
      setState(() {
        _isScrolling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topics.isEmpty) {
      return const Center(child: Text('No topics available'));
    }

    return ScrollablePositionedList.builder(
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
                border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                          if (value == true && widget.onForgetPressed != null) {
                            print(
                                'TopicPostsContainer: Forget checkbox clicked');
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
          ],
        );
      },
    );
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
    _itemPositionsListener.itemPositions.removeListener(_updateCurrentIndex);
    super.dispose();
  }
}
