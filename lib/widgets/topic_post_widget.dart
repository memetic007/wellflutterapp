import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'post_widget.dart';

class TopicPostWidget extends StatelessWidget {
  final Topic topic;

  const TopicPostWidget({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: topic.posts.length,
      itemBuilder: (context, index) {
        return PostWidget(post: topic.posts[index]);
      },
    );
  }
}
