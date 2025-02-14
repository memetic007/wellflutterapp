import 'package:flutter/material.dart';
import '../models/topic.dart';

class TopicPostWidget extends StatelessWidget {
  final Topic topic;
  final int? index; // Keep these for now as they might be used elsewhere
  final int? total;

  const TopicPostWidget({
    super.key,
    required this.topic,
    this.index,
    this.total,
  });

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Row(
                    children: [
                      Expanded(
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
                              TextSpan(text: topic.title),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text('Forget'),
                          Checkbox(
                            value: false,
                            onChanged: (_) =>
                                _showMessage(context, 'Forget clicked'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Posts content section
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPostsText(),
                ),
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _showMessage(context, 'Reply pressed'),
                    child: const Text('Reply'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showMessage(context, 'Update pressed'),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsText() {
    final buffer = StringBuffer();
    const int maxLineLength = 80;
    const String headerPrefix = ' '; // 1 space for header
    const String textAreaPrefix = '   '; // 3 spaces for text

    String wrapLine(String line) {
      const int maxContentLength = 77; // 80 - 3 spaces for prefix

      if (line.length <= maxContentLength) {
        return textAreaPrefix + line;
      }

      final words = line.split(' ');
      final wrappedLines = <String>[];
      String currentLine = '';

      for (final word in words) {
        if (currentLine.isEmpty) {
          currentLine = word;
        } else if (('$currentLine $word').length <= maxContentLength) {
          currentLine += ' $word';
        } else {
          wrappedLines.add(textAreaPrefix + currentLine);
          currentLine = word;
        }
      }
      if (currentLine.isNotEmpty) {
        wrappedLines.add(textAreaPrefix + currentLine);
      }

      return wrappedLines.join('\n');
    }

    // Unicode bold characters mapping
    const Map<String, String> boldMap = {
      'a': '𝗮',
      'b': '𝗯',
      'c': '𝗰',
      'd': '𝗱',
      'e': '𝗲',
      'f': '𝗳',
      'g': '𝗴',
      'h': '𝗵',
      'i': '𝗶',
      'j': '𝗷',
      'k': '𝗸',
      'l': '𝗹',
      'm': '𝗺',
      'n': '𝗻',
      'o': '𝗼',
      'p': '𝗽',
      'q': '𝗾',
      'r': '𝗿',
      's': '𝘀',
      't': '𝘁',
      'u': '𝘂',
      'v': '𝘃',
      'w': '𝘄',
      'x': '𝘅',
      'y': '𝘆',
      'z': '𝘇',
      'A': '𝗔',
      'B': '𝗕',
      'C': '𝗖',
      'D': '𝗗',
      'E': '𝗘',
      'F': '𝗙',
      'G': '𝗚',
      'H': '𝗛',
      'I': '𝗜',
      'J': '𝗝',
      'K': '𝗞',
      'L': '𝗟',
      'M': '𝗠',
      'N': '𝗡',
      'O': '𝗢',
      'P': '𝗣',
      'Q': '𝗤',
      'R': '𝗥',
      'S': '𝗦',
      'T': '𝗧',
      'U': '𝗨',
      'V': '𝗩',
      'W': '𝗪',
      'X': '𝗫',
      'Y': '𝗬',
      'Z': '𝗭',
      '0': '𝟬',
      '1': '𝟭',
      '2': '𝟮',
      '3': '𝟯',
      '4': '𝟰',
      '5': '𝟱',
      '6': '𝟲',
      '7': '𝟳',
      '8': '𝟴',
      '9': '𝟵',
      ' ': ' ',
      '(': '(',
      ')': ')',
      '-': '-',
      ':': ':',
      ',': ',',
      '.': '.',
    };

    String toBold(String text) {
      return text.split('').map((char) => boldMap[char] ?? char).join();
    }

    for (var i = 0; i < topic.posts.length; i++) {
      final post = topic.posts[i];
      // Add header prefix to the header line
      buffer.writeln(headerPrefix +
          toBold('${post.username} (${post.pseud}) - ${post.datetime}'));
      buffer.writeln();
      for (var line in post.text) {
        buffer.writeln(wrapLine(line));
      }
      if (i < topic.posts.length - 1) {
        buffer.writeln('-' * 40);
      }
    }

    return SelectableText(
      buffer.toString(),
      style: const TextStyle(
        fontFamily: 'Consolas', // Darker, clearer monospace font
        fontWeight: FontWeight.w500, // Slightly bolder
        height: 1.5,
        color: Color(0xFF202020), // Dark gray for better contrast
      ),
    );
  }
}
