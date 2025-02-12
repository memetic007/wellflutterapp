import 'package:flutter/material.dart';
import '../models/topic.dart';

class TopicsView extends StatelessWidget {
  final List<Topic> topics;
  final Function(Topic) onTopicSelected;

  const TopicsView({
    super.key,
    required this.topics,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return GestureDetector(
              onDoubleTap: () => onTopicSelected(topic),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: RichText(
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
                        TextSpan(text: topic.title),
                      ],
                    ),
                  ),
                  subtitle: Text('${topic.posts.length} posts'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 