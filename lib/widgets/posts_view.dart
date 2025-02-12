import 'package:flutter/material.dart';
import '../models/topic.dart';

class PostsView extends StatelessWidget {
  final Topic topic;

  const PostsView({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topic header
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '[${topic.conf}] ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                TextSpan(
                  text: '${topic.title} (${topic.posts.length} posts)',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Posts content
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(_buildPostsText()),
            ),
          ),
        ),
      ],
    );
  }

  String _buildPostsText() {
    final buffer = StringBuffer();
    
    for (var i = 0; i < topic.posts.length; i++) {
      final post = topic.posts[i];
      buffer.writeln('${post.username} (${post.pseud}) - ${post.datetime}');
      buffer.writeln();
      for (var line in post.text) {
        buffer.writeln(line);
      }
      if (i < topic.posts.length - 1) {
        buffer.writeln('-' * 40); // Separator line
      }
    }
    
    return buffer.toString();
  }
} 