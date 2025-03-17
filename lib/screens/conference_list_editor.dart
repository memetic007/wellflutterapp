import 'package:flutter/material.dart';

class ConferenceListEditor extends StatefulWidget {
  // ... (existing code)
  @override
  _ConferenceListEditorState createState() => _ConferenceListEditorState();
}

class _ConferenceListEditorState extends State<ConferenceListEditor> {
  // ... (existing code)

  void _saveConferenceList() async {
    final List<String> conferenceList = _textController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final result = await _apiService.putCfList(conferenceList);

    if (result['success']) {
      // Remove the extraneous popup and just close the dialog with success result
      Navigator.of(context).pop(true);

      // Show a snackbar instead of a popup
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conference list saved successfully'),
            behavior: SnackBarBehavior.floating,
            width: MediaQuery.of(context).size.width * 0.3,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Show error in a dialog
      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
}
