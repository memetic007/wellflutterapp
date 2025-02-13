import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'topic_post_widget.dart';

class TopicPostsContainer extends StatefulWidget {
  final List<Topic> topics;

  const TopicPostsContainer({
    super.key,
    required this.topics,
  });

  @override
  State<TopicPostsContainer> createState() => _TopicPostsContainerState();
}

class _TopicPostsContainerState extends State<TopicPostsContainer> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(
      widget.topics.length,
      (index) => GlobalKey(),
    ));
  }

  void _scrollToNext(int currentIndex) {
    if (currentIndex >= widget.topics.length - 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('No More Topics'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final currentBox =
        _keys[currentIndex].currentContext?.findRenderObject() as RenderBox?;
    if (currentBox != null) {
      final currentHeight = currentBox.size.height;

      _scrollController.animateTo(
        _scrollController.offset + currentHeight,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToPrevious(int currentIndex) {
    if (currentIndex <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('No Previous Topics'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final previousBox = _keys[currentIndex - 1]
        .currentContext
        ?.findRenderObject() as RenderBox?;
    if (previousBox != null) {
      final previousHeight = previousBox.size.height;

      _scrollController.animateTo(
        _scrollController.offset - previousHeight,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.topics.length,
      itemBuilder: (context, index) {
        return TopicPostWidget(
          key: _keys[index],
          topic: widget.topics[index],
          index: index,
          total: widget.topics.length,
          onNextPressed: () => _scrollToNext(index),
          onPreviousPressed: () => _scrollToPrevious(index),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
