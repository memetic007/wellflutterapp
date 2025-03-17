import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  // ... (existing code)
}

class _MainScreenState extends State<MainScreen> {
  // ... (existing code)

  void _showConferenceListEditor() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConferenceListEditor(
        initialConferences: _conferences,
        apiService: _apiService,
      ),
    );

    // If the editor returned true, it means the list was saved successfully
    // No need to show another popup, just refresh the conferences
    if (result == true) {
      _refreshConferences();
    }
  }

  // ... (rest of the existing code)
}
