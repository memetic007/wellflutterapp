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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
        ),
        child: Column(
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
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '[${widget.topic.handle}] ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          TextSpan(
                            text: widget.topic.title,
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
              child: Scrollbar(
                thumbVisibility: true,
                interactive: true,
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: widget.topic.posts.map((post) => PostWidget(post: post)).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
