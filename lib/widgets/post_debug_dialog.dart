import 'package:flutter/material.dart';
import '../models/post_debug_entry.dart';
import '../services/post_debug_service.dart';
// We'll handle date formatting manually until intl package is available

class PostDebugDialog extends StatelessWidget {
  const PostDebugDialog({super.key});

  // Simple date formatter function
  String formatDateTime(DateTime dateTime) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    final year = dateTime.year;
    final month = twoDigits(dateTime.month);
    final day = twoDigits(dateTime.day);
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    final second = twoDigits(dateTime.second);
    
    return '$year-$month-$day $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final entries = PostDebugService().getEntries();
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Post Debug History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (entries.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          PostDebugService().clear();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Clear History'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No post history available',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            title: Text(
                              'Post at ${formatDateTime(entry.timestamp)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: entry.success ? Colors.blue : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              entry.success ? 'Success' : 'Failed',
                              style: TextStyle(
                                color: entry.success ? Colors.green : Colors.red,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PowerShell Command:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: SelectableText(
                                        entry.command,
                                        style: const TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Response:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: SelectableText(
                                        entry.response,
                                        style: const TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (entry.stderr.isNotEmpty) ...[
                                      const Text(
                                        'Errors:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.pink[50],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red[300]!),
                                        ),
                                        child: SelectableText(
                                          entry.stderr,
                                          style: const TextStyle(
                                            fontFamily: 'Courier New',
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Text(
                                      'Original Post:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: SelectableText(
                                        entry.originalText,
                                        style: const TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 