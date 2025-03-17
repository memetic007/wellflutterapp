import 'package:flutter/material.dart';

class ConferenceListEditor extends StatefulWidget {
  // ... (existing code)

  @override
  _ConferenceListEditorState createState() => _ConferenceListEditorState();
}

class _ConferenceListEditorState extends State<ConferenceListEditor> {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Conference List'),
      content: TextField(
        controller: _textController,
        maxLines: 15,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter conferences, one per line',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final List<String> conferenceList = _textController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();

            final result = await _apiService.putCfList(conferenceList);

            if (result['success']) {
              // Remove this dialog that's causing the extraneous popup
              // showDialog(
              //   context: context,
              //   builder: (context) => AlertDialog(
              //     title: const Text('Save'),
              //     content: const Text('saved pressed'),
              //     actions: [
              //       TextButton(
              //         onPressed: () => Navigator.of(context).pop(),
              //         child: const Text('OK'),
              //       ),
              //     ],
              //   ),
              // );
              
              // Just close the editor with success result
              Navigator.of(context).pop(true);
            } else {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to save: ${result['error']}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 