import 'package:flutter/material.dart';

class ConferenceEditor extends StatefulWidget {
  // ... (existing code)
}

class _ConferenceEditorState extends State<ConferenceEditor> {
  // ... (existing code)

  void _handleSave() async {
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
  }

  // ... (rest of the existing code)
}
