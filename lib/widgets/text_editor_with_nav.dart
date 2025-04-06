import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextEditorWithNav extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  final bool expands;

  const TextEditorWithNav({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.style,
    this.decoration,
    this.maxLines,
    this.expands = false,
  });

  @override
  State<TextEditorWithNav> createState() => _TextEditorWithNavState();
}

class _TextEditorWithNavState extends State<TextEditorWithNav> {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          _handleKeyEvent(event);
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        style: widget.style,
        decoration: widget.decoration,
        maxLines: widget.maxLines,
        expands: widget.expands,
        focusNode: _focusNode,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    final int currentPosition = widget.controller.selection.baseOffset;
    final String text = widget.controller.text;

    if (event.physicalKey == PhysicalKeyboardKey.numpad4) {
      // Left arrow
      if (currentPosition > 0) {
        widget.controller.selection = TextSelection.collapsed(
          offset: currentPosition - 1,
        );
      }
    } else if (event.physicalKey == PhysicalKeyboardKey.numpad6) {
      // Right arrow
      if (currentPosition < text.length) {
        widget.controller.selection = TextSelection.collapsed(
          offset: currentPosition + 1,
        );
      }
    } else if (event.physicalKey == PhysicalKeyboardKey.numpad8) {
      // Up arrow
      final int lineStart = text.lastIndexOf('\n', currentPosition - 1) + 1;
      final int prevLineStart = text.lastIndexOf('\n', lineStart - 2) + 1;
      final int column = currentPosition - lineStart;
      final int newPosition =
          prevLineStart + column.clamp(0, lineStart - prevLineStart - 1);
      widget.controller.selection =
          TextSelection.collapsed(offset: newPosition.clamp(0, text.length));
    } else if (event.physicalKey == PhysicalKeyboardKey.numpad2) {
      // Down arrow
      final int lineStart = text.lastIndexOf('\n', currentPosition - 1) + 1;
      final int nextLineStart = text.indexOf('\n', currentPosition);
      if (nextLineStart != -1) {
        final int nextNextLineStart = text.indexOf('\n', nextLineStart + 1);
        final int column = currentPosition - lineStart;
        final int newPosition = nextLineStart +
            1 +
            column.clamp(
                0,
                (nextNextLineStart == -1 ? text.length : nextNextLineStart) -
                    nextLineStart -
                    1);
        widget.controller.selection =
            TextSelection.collapsed(offset: newPosition);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
