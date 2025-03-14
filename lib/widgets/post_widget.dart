import 'package:flutter/material.dart';
import '../models/post.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final bool showHeader; // Option to show/hide header

  const PostWidget({
    super.key,
    required this.post,
    this.showHeader = true,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(maxWidth: 800), // Set a consistent maximum width
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText.rich(
            TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                if (widget.showHeader) ...[
                  TextSpan(
                    text: widget.post.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  TextSpan(
                    text: ' (${widget.post.pseud})',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: '  ${widget.post.handle}\n',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '${widget.post.datetime}\n\n',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
                ...widget.post.text.map((line) {
                  return TextSpan(
                    text: '$line\n',
                    style: const TextStyle(
                      height: 1.4,
                      fontSize: 15,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
