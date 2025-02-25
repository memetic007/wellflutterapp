import 'package:flutter/material.dart';
import '../models/post_debug_entry.dart';
import '../services/post_debug_service.dart';
// We'll handle date formatting manually until intl package is available

class PostDebugDialog extends StatefulWidget {
  const PostDebugDialog({super.key});

  @override
  State<PostDebugDialog> createState() => _PostDebugDialogState();
}

class _PostDebugDialogState extends State<PostDebugDialog> {
  PostDebugEntry? _selectedEntry;
  final ScrollController _scrollController = ScrollController();

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
                Text(
                  _selectedEntry == null ? 'Post Debug History' : 'Post Debug Details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_selectedEntry != null)
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to List'),
                        onPressed: () {
                          setState(() {
                            _selectedEntry = null;
                          });
                        },
                      ),
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
              child: _selectedEntry == null
                  ? ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              formatDateTime(entry.timestamp),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.widgetSource != null && entry.widgetSource.isNotEmpty)
                                  Text('Source: ${entry.widgetSource}'),
                                Text(
                                  entry.originalText.length > 50
                                      ? '${entry.originalText.substring(0, 50)}...'
                                      : entry.originalText,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              entry.success ? Icons.check_circle : Icons.error,
                              color: entry.success ? Colors.green : Colors.red,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedEntry = entry;
                              });
                              // Reset scroll position when viewing a new entry
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                              });
                            },
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Time: ${formatDateTime(_selectedEntry!.timestamp)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        _selectedEntry!.success ? Icons.check_circle : Icons.error,
                                        color: _selectedEntry!.success ? Colors.green : Colors.red,
                                      ),
                                    ],
                                  ),
                                  if (_selectedEntry!.widgetSource != null && 
                                      _selectedEntry!.widgetSource.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Source: ${_selectedEntry!.widgetSource}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
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
                                      _selectedEntry!.command,
                                      style: const TextStyle(
                                        fontFamily: 'Courier New',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'PowerShell Response:',
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
                                      _selectedEntry!.response,
                                      style: const TextStyle(
                                        fontFamily: 'Courier New',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (_selectedEntry!.stderr.isNotEmpty) ...[
                                    const Text(
                                      'Errors:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
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
                                        _selectedEntry!.stderr,
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
                                      _selectedEntry!.originalText,
                                      style: const TextStyle(
                                        fontFamily: 'Courier New',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 