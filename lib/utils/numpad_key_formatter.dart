import 'package:flutter/services.dart';

class NumpadKeyFormatter extends TextInputFormatter {
  final Function(LogicalKeyboardKey) onArrowKey;
  final Function() onDelete;

  NumpadKeyFormatter({
    required this.onArrowKey,
    required this.onDelete,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if the text has changed in a way that indicates a numpad key press
    if (newValue.text.length > oldValue.text.length) {
      final newChar = newValue.text[newValue.selection.baseOffset - 1];
      switch (newChar) {
        case '8':
          onArrowKey(LogicalKeyboardKey.arrowUp);
          return oldValue;
        case '2':
          onArrowKey(LogicalKeyboardKey.arrowDown);
          return oldValue;
        case '4':
          onArrowKey(LogicalKeyboardKey.arrowLeft);
          return oldValue;
        case '6':
          onArrowKey(LogicalKeyboardKey.arrowRight);
          return oldValue;
        case '7':
          onArrowKey(LogicalKeyboardKey.home);
          return oldValue;
        case '1':
          onArrowKey(LogicalKeyboardKey.end);
          return oldValue;
        case '.':
          onDelete();
          return oldValue;
      }
    }

    return newValue;
  }
}
