import 'package:flutter/material.dart';

class EditConferenceListDialog extends StatefulWidget {
  // ... (existing code)
}

class _EditConferenceListDialogState extends State<EditConferenceListDialog> {
  // ... (existing code)

  void _saveConferenceList() async {
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
          content: Text('Failed to save conference list: ${result['error']}'),
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