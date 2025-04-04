import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
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
  // Regular expression to match URLs
  static final _urlRegExp = RegExp(
    r'(?:(?:https?:\/\/|www\.)\S+\.[a-zA-Z]{2,}(?:\/[^\s]*)?|\S+\.(?:com|net|org|ai|dev|io))\b',
    caseSensitive: false,
  );

  // Launch URL in browser
  Future<void> _launchUrl(String url) async {
    // Add https:// if the URL doesn't start with a protocol
    final urlString = url.startsWith('http')
        ? url
        : url.startsWith('www.')
            ? 'https://$url'
            : 'https://$url';
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Convert text to list of TextSpans with clickable URLs
  List<TextSpan> _buildTextSpans(String text) {
    final spans = <TextSpan>[];
    var start = 0;

    for (final match in _urlRegExp.allMatches(text)) {
      // Add text before the URL
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      // Add the URL as a clickable span
      final url = text.substring(match.start, match.end);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
        ),
      );

      start = match.end;
    }

    // Add any remaining text after the last URL
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

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
                ...(widget.post.text is List<String>
                    ? _buildTextSpans(
                        (widget.post.text as List<String>).join('\n'))
                    : _buildTextSpans(widget.post.text.toString())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
