import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextEditorWithNav extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final int? maxLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? style;
  final bool autofocus;

  const TextEditorWithNav({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.maxLines,
    this.expands = false,
    this.textAlignVertical,
    this.style,
    this.autofocus = false,
  });

  @override
  State<TextEditorWithNav> createState() => _TextEditorWithNavState();
}

class _TextEditorWithNavState extends State<TextEditorWithNav> {
  late FocusNode _focusNode;
  final FocusNode _rawKeyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _rawKeyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Get current cursor position and text
      final TextEditingValue value = widget.controller.value;
      
      // Handle case where selection might be invalid
      if (value.selection.baseOffset < 0) {
        return;
      }

      final int cursorPos = value.selection.baseOffset;
      final String text = value.text;
      int newPos = cursorPos;

      // Handle different numpad keys
      if (event.physicalKey == PhysicalKeyboardKey.numpad4 ||
          (event.physicalKey == PhysicalKeyboardKey.arrowLeft && 
           event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
        // Left arrow - move cursor one character left
        if (cursorPos > 0) {
          newPos = cursorPos - 1;
        }
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad6 ||
                (event.physicalKey == PhysicalKeyboardKey.arrowRight && 
                 event.logicalKey == LogicalKeyboardKey.arrowRight)) {
        // Right arrow - move cursor one character right
        if (cursorPos < text.length) {
          newPos = cursorPos + 1;
        }
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad8 ||
                (event.physicalKey == PhysicalKeyboardKey.arrowUp && 
                 event.logicalKey == LogicalKeyboardKey.arrowUp)) {
        // Up arrow - move cursor to previous line at similar horizontal position
        if (text.isEmpty) return;

        try {
          // Get all lines in the text
          List<String> lines = text.split('\n');
          
          // Find which line we're currently on
          int currentLineIndex = 0;
          int charCount = 0;
          
          // Find the current line by counting characters
          for (int i = 0; i < lines.length; i++) {
            if (charCount + lines[i].length >= cursorPos) {
              currentLineIndex = i;
              break;
            }
            // Add 1 for the newline character
            charCount += lines[i].length + 1;
          }
          
          // If we're on the first line, can't go up
          if (currentLineIndex <= 0) return;
          
          // Calculate column position in current line
          int columnInCurrentLine = cursorPos - charCount;
          
          // Calculate position at start of previous line
          int prevLineStart = 0;
          for (int i = 0; i < currentLineIndex - 1; i++) {
            prevLineStart += lines[i].length + 1; // +1 for newline
          }
          
          // Calculate position in previous line
          int prevLineLength = lines[currentLineIndex - 1].length;
          int columnInPrevLine = columnInCurrentLine < prevLineLength
              ? columnInCurrentLine
              : prevLineLength;
          
          // Set new position
          newPos = prevLineStart + columnInPrevLine;
        } catch (e) {
          // Fallback: just try to find the previous newline
          if (cursorPos > 0) {
            final int lastNewlineIndex = text.lastIndexOf('\n', cursorPos - 1);
            if (lastNewlineIndex >= 0) {
              // Find the newline before that one
              final int prevNewlineIndex = text.lastIndexOf('\n', lastNewlineIndex - 1);
              if (prevNewlineIndex >= 0) {
                // Try to maintain the same column position
                final int currentColumn = cursorPos - lastNewlineIndex - 1;
                final int prevLineLength = lastNewlineIndex - prevNewlineIndex - 1;
                newPos = prevNewlineIndex + 1 + (currentColumn < prevLineLength ? currentColumn : prevLineLength);
              } else {
                // We're moving to the first line
                final int currentColumn = cursorPos - lastNewlineIndex - 1;
                newPos = currentColumn < lastNewlineIndex ? currentColumn : lastNewlineIndex;
              }
            }
          }
        }
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad2 ||
                (event.physicalKey == PhysicalKeyboardKey.arrowDown && 
                 event.logicalKey == LogicalKeyboardKey.arrowDown)) {
        // Down arrow - move cursor to next line at similar horizontal position
        if (text.isEmpty) return;

        try {
          // Get all lines in the text
          List<String> lines = text.split('\n');
          
          // Find which line we're currently on
          int currentLineIndex = 0;
          int charCount = 0;
          
          // Find the current line by counting characters
          for (int i = 0; i < lines.length; i++) {
            if (charCount + lines[i].length >= cursorPos) {
              currentLineIndex = i;
              break;
            }
            // Add 1 for the newline character
            charCount += lines[i].length + 1;
          }
          
          // If we're on the last line, can't go down
          if (currentLineIndex >= lines.length - 1) return;
          
          // Calculate column position in current line
          int columnInCurrentLine = cursorPos - charCount;
          
          // Calculate position at start of next line
          int nextLineStart = 0;
          for (int i = 0; i <= currentLineIndex; i++) {
            nextLineStart += lines[i].length + 1; // +1 for newline
          }
          
          // Calculate position in next line
          int nextLineLength = lines[currentLineIndex + 1].length;
          int columnInNextLine = columnInCurrentLine < nextLineLength
              ? columnInCurrentLine
              : nextLineLength;
          
          // Set new position
          newPos = nextLineStart + columnInNextLine;
        } catch (e) {
          // Fallback: just try to find the next newline and move after it
          final int nextLineStart = text.indexOf('\n', cursorPos);
          if (nextLineStart >= 0 && nextLineStart + 1 < text.length) {
            newPos = nextLineStart + 1;
          }
        }
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad7 ||
                (event.physicalKey == PhysicalKeyboardKey.home && 
                 event.logicalKey == LogicalKeyboardKey.home)) {
        // Home - move cursor to start of line
        if (text.isEmpty) return;

        if (cursorPos > 0) {
          final int lastNewlineIndex = text.lastIndexOf('\n', cursorPos - 1);
          newPos = lastNewlineIndex >= 0 ? lastNewlineIndex + 1 : 0;
        } else {
          newPos = 0;
        }
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad1 ||
                (event.physicalKey == PhysicalKeyboardKey.end && 
                 event.logicalKey == LogicalKeyboardKey.end)) {
        // End - move cursor to end of line
        if (text.isEmpty) return;

        final int nextNewline = text.indexOf('\n', cursorPos);
        newPos = nextNewline >= 0 ? nextNewline : text.length;
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad9 ||
                (event.physicalKey == PhysicalKeyboardKey.pageUp && 
                 event.logicalKey == LogicalKeyboardKey.pageUp)) {
        // Page Up - move cursor up several lines
        if (text.isEmpty) return;

        int linesUp = 10;
        int tempPos = cursorPos;
        while (linesUp > 0 && tempPos > 0) {
          final int prevNewline = text.lastIndexOf('\n', tempPos - 1);
          if (prevNewline >= 0) {
            tempPos = prevNewline;
            linesUp--;
          } else {
            break;
          }
        }
        newPos = tempPos > 0 ? tempPos + 1 : 0;
      } else if (event.physicalKey == PhysicalKeyboardKey.numpad3 ||
                (event.physicalKey == PhysicalKeyboardKey.pageDown && 
                 event.logicalKey == LogicalKeyboardKey.pageDown)) {
        // Page Down - move cursor down several lines
        if (text.isEmpty) return;

        int linesDown = 10;
        int tempPos = cursorPos;
        while (linesDown > 0 && tempPos < text.length) {
          final int nextNewline = text.indexOf('\n', tempPos);
          if (nextNewline >= 0) {
            tempPos = nextNewline + 1;
            linesDown--;
          } else {
            tempPos = text.length;
            break;
          }
        }
        newPos = tempPos;
      }

      // Update cursor position if it changed
      if (newPos != cursorPos) {
        widget.controller.selection =
            TextSelection.fromPosition(TextPosition(offset: newPos));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _rawKeyboardFocusNode,
      onKey: _handleKeyEvent,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        expands: widget.expands,
        textAlignVertical: widget.textAlignVertical ?? TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        enableInteractiveSelection: true,
        textInputAction: TextInputAction.newline,
        enableSuggestions: true,
        style: widget.style,
        decoration: widget.decoration?.copyWith(
          alignLabelWithHint: true,
        ) ?? const InputDecoration(
          alignLabelWithHint: true,
        ),
      ),
    );
  }
} 