import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _useConfs = false;
  
  static const String _directorySaveKey = 'last_directory';
  
  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
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

  Future<void> _loadSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDirectory = prefs.getString(_directorySaveKey);
    if (savedDirectory != null) {
      setState(() {
        _directoryController.text = savedDirectory;
      });
    }
  }

  Future<void> _saveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_directorySaveKey, _directoryController.text.trim());
  }

  Future<void> _executeCommand() async {
    try {
      final dir = _directoryController.text.trim();
      final cmd = _commandController.text.trim();
      if (cmd.isEmpty) return;

      if (dir.isNotEmpty) {
        await _saveDirectory();
      }

      // Modify the command based on checkbox state
      final makeObjectsCommand = _useConfs 
          ? 'python makeobjects2json.py -conf'
          : 'python makeobjects2json.py';

      // Construct the Python command with the user input
      final pythonCommand = 'python remoteexec.py --username memetic --password labor+da -- "extract $cmd" | python extract2json.py | $makeObjectsCommand';

      // Combine with directory change if directory is specified
      final fullCommand = dir.isNotEmpty 
          ? 'cd "$dir" ; $pythonCommand'
          : pythonCommand;

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
        title: const Text('WELL App Prototype v 0.0.2'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Directory input row
            Row(
              children: [
                const Text('Directory: ', 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _directoryController,
                      decoration: const InputDecoration(
                        hintText: 'Enter directory path...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Command input row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _commandController,
                      decoration: const InputDecoration(
                        hintText: 'Enter command...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text('Confs '),
                    Checkbox(
                      value: _useConfs,
                      onChanged: (bool? value) {
                        setState(() {
                          _useConfs = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 8),
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 400.0,
                ),
                child: TextField(
                  controller: _outputController,
                  maxLines: null,
                  readOnly: true,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    contentPadding: EdgeInsets.all(8),
                    isCollapsed: true,
                  ),
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