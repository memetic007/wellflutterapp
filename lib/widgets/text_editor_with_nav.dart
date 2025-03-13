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
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFieldFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void _handleArrowKey(LogicalKeyboardKey key) {
    final selection = widget.controller.selection;
    final text = widget.controller.text;
    final lines = text.split('\n');
    int currentLine = 0;
    int currentColumn = selection.start;

    // Find current line and column
    for (var i = 0; i < lines.length; i++) {
      if (currentColumn > lines[i].length) {
        currentColumn -= lines[i].length + 1; // +1 for newline
        currentLine++;
      } else {
        break;
      }
    }

    int newOffset = selection.start;

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        if (selection.start > 0) {
          newOffset = selection.start - 1;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (selection.start < text.length) {
          newOffset = selection.start + 1;
        }
        break;
      case LogicalKeyboardKey.arrowUp:
        if (currentLine > 0) {
          final previousLineLength = lines[currentLine - 1].length;
          final previousLineStart = _getLineStart(text, currentLine - 1);
          newOffset = previousLineStart +
              (currentColumn < previousLineLength
                  ? currentColumn
                  : previousLineLength);
        }
        break;
      case LogicalKeyboardKey.arrowDown:
        if (currentLine < lines.length - 1) {
          final nextLineLength = lines[currentLine + 1].length;
          final nextLineStart = _getLineStart(text, currentLine + 1);
          newOffset = nextLineStart +
              (currentColumn < nextLineLength ? currentColumn : nextLineLength);
        }
        break;
      case LogicalKeyboardKey.home:
        newOffset = _getLineStart(text, currentLine);
        break;
      case LogicalKeyboardKey.end:
        newOffset =
            _getLineStart(text, currentLine) + lines[currentLine].length;
        break;
      default:
        return;
    }

    widget.controller.selection = TextSelection.collapsed(offset: newOffset);
  }

  void _handleDelete() {
    final selection = widget.controller.selection;
    final text = widget.controller.text;

    // Check if we have a valid selection and text
    if (selection.start < 0 || selection.start >= text.length) {
      return;
    }

    if (selection.start < text.length) {
      final newText =
          text.replaceRange(selection.start, selection.start + 1, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  int _getLineStart(String text, int lineNumber) {
    final lines = text.split('\n');
    int offset = 0;
    for (var i = 0; i < lineNumber; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardListenerFocusNode,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.physicalKey == PhysicalKeyboardKey.numpad4) {
            _handleArrowKey(LogicalKeyboardKey.arrowLeft);
          } else if (event.physicalKey == PhysicalKeyboardKey.numpad6) {
            _handleArrowKey(LogicalKeyboardKey.arrowRight);
          } else if (event.physicalKey == PhysicalKeyboardKey.numpad8) {
            _handleArrowKey(LogicalKeyboardKey.arrowUp);
          } else if (event.physicalKey == PhysicalKeyboardKey.numpad2) {
            _handleArrowKey(LogicalKeyboardKey.arrowDown);
          } else if (event.physicalKey == PhysicalKeyboardKey.numpad7) {
            _handleArrowKey(LogicalKeyboardKey.home);
          } else if (event.physicalKey == PhysicalKeyboardKey.numpad1) {
            _handleArrowKey(LogicalKeyboardKey.end);
          } else if (event.physicalKey == PhysicalKeyboardKey.numpadDecimal) {
            _handleDelete();
          }
        }
      },
      child: TextField(
        controller: widget.controller,
        focusNode: _textFieldFocusNode,
        style: widget.style,
        decoration: widget.decoration,
        maxLines: widget.maxLines,
        expands: widget.expands,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }
}
