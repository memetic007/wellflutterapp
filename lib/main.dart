import 'package:flutter/material.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Command Line Interface',
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
  
  Future<void> _executeCommand() async {
    try {
      final command = _commandController.text.split(' ');
      if (command.isEmpty) return;

      final process = await Process.run(
        command[0],
        command.length > 1 ? command.sublist(1) : [],
        runInShell: true,
      );

      setState(() {
        _outputController.text += '> ${_commandController.text}\n';
        _outputController.text += process.stdout.toString();
        if (process.stderr.toString().isNotEmpty) {
          _outputController.text += process.stderr.toString();
        }
        _outputController.text += '\n';
      });
      
      _commandController.clear();
    } catch (e) {
      setState(() {
        _outputController.text += '> ${_commandController.text}\n';
        _outputController.text += 'Error: $e\n\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Line Interface'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _executeCommand(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _executeCommand,
                  child: const Text('Submit'),
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
    super.dispose();
  }
} 