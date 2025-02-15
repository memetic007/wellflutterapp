import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'post_widget.dart';

class TopicPostWidget extends StatefulWidget {
  final Topic topic;
  final VoidCallback? onForgetPressed;

  const TopicPostWidget({
    super.key,
    required this.topic,
    this.onForgetPressed,
  });

  @override
  State<TopicPostWidget> createState() => _TopicPostWidgetState();
}

class _TopicPostWidgetState extends State<TopicPostWidget> {
  bool _isForgetChecked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Row(
                  children: [
                    Text(
                      widget.topic.handle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.topic.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                      if (value == true && widget.onForgetPressed != null) {
                        print('DEBUG - TopicPostWidget:');
                        print('  - Topic title: "${widget.topic.title}"');
                        print('  - Topic handle: "${widget.topic.handle}"');
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
          child: ListView.builder(
            itemCount: widget.topic.posts.length,
            itemBuilder: (context, index) {
              return PostWidget(post: widget.topic.posts[index]);
            },
          ),
        ),
      ],
    );
  }
}
