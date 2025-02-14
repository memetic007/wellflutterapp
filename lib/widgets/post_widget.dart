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
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with user info and timestamp
          if (widget.showHeader)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
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
                            text: '\n${widget.post.datetime}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    widget.post.handle,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Post content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.post.text.map((line) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    line,
                    style: const TextStyle(
                      height: 1.4,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Footer with save checkbox
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isSaved,
                      onChanged: (value) {
                        setState(() {
                          _isSaved = value ?? false;
                        });
                        if (value ?? false) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Save clicked for ${widget.post.handle}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              behavior: SnackBarBehavior.floating,
                              width: 300,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reply pressed for ${widget.post.handle}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        behavior: SnackBarBehavior.floating,
                        width: 300,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Reply'),
                ),
                Text(
                  widget.post.datetime_iso8601,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
