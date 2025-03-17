import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ... (existing code)

  void _editConferenceList() async {
    final List<String> currentList = await _apiService.getCfList().then(
          (result) => result['success']
              ? (result['cflist'] as List<String>)
              : <String>[],
        );

    final TextEditingController textController = TextEditingController(
      text: currentList.join('\n'),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Conference List'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: TextField(
            controller: textController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter conferences, one per line',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final List<String> conferenceList = textController.text
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
      ),
    );

    if (result == true) {
      setState(() {
        // Refresh the UI if needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
}
