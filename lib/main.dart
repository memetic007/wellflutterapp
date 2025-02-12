import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WELL App Prototype',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CommandInterface(),
    );
  }
}

class CommandInterface extends StatefulWidget {
  const CommandInterface({super.key});

  @override
  State<CommandInterface> createState() => _CommandInterfaceState();
}

class _CommandInterfaceState extends State<CommandInterface> {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _directoryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        // Check if Ctrl is pressed using HardwareKeyboard
        final isControlPressed = HardwareKeyboard.instance.isControlPressed;
        
        if (event.logicalKey == LogicalKeyboardKey.numpad1 && isControlPressed) {
          _commandController.selection = TextSelection.fromPosition(
            TextPosition(offset: _commandController.text.length),
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.numpad7 && isControlPressed) {
          _commandController.selection = const TextSelection.collapsed(offset: 0);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.delete || 
                  event.logicalKey == LogicalKeyboardKey.numpadDecimal) {
          final selection = _commandController.selection;
          if (selection.start < _commandController.text.length) {
            final text = _commandController.text;
            final newText = text.replaceRange(selection.start, selection.start + 1, '');
            _commandController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start),
            );
          }
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  Future<void> _executeCommand() async {
    try {
      final dir = _directoryController.text.trim();
      final cmd = _commandController.text.trim();
      if (cmd.isEmpty) return;

      // Combine directory change with the command
      final fullCommand = dir.isNotEmpty 
          ? 'cd "${dir}" ; ${cmd}'
          : cmd;

      final process = await Process.run(
        'powershell.exe',
        ['-Command', fullCommand],
        runInShell: true,
      );

      setState(() {
        _outputController.text += 'PS> $fullCommand\n';
        _outputController.text += process.stdout.toString();
        if (process.stderr.toString().isNotEmpty) {
          _outputController.text += process.stderr.toString();
        }
        _outputController.text += '\n';
      });
      
      _commandController.clear();
    } catch (e) {
      setState(() {
        _outputController.text += 'PS> ${_commandController.text}\n';
        _outputController.text += 'Error: $e\n\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WELL App Prototype'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Directory: ', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _directoryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter directory path...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _executeCommand(),
                    enableInteractiveSelection: true,
                    contextMenuBuilder: (context, editableTextState) {
                      return AdaptiveTextSelectionToolbar.editableText(
                        editableTextState: editableTextState,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _executeCommand,
                  child: const Text('Submit'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _outputController.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _outputController,
                maxLines: null,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _outputController.dispose();
    _directoryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
} 