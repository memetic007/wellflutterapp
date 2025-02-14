import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'topic_post_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TopicPostsContainer extends StatefulWidget {
  final List<Topic> topics;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const TopicPostsContainer({
    super.key,
    required this.topics,
    this.onPrevious,
    this.onNext,
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

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_updateCurrentIndex);
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

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemCount: widget.topics.length,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemBuilder: (context, index) {
        return TopicPostWidget(
          key: ValueKey('topic_$index'),
          topic: widget.topics[index],
          index: index,
          total: widget.topics.length,
          onNextPressed: scrollToNext,
          onPreviousPressed: scrollToPrevious,
        );
      },
    );
  }

  String get currentPositionText {
    return 'Topic ${_currentIndex + 1} of ${widget.topics.length}';
  }

  bool get isScrolling => _isScrolling;

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_updateCurrentIndex);
    super.dispose();
  }
}
