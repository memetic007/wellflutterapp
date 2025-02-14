import 'package:flutter/material.dart';
import 'screens/command_interface.dart';
import 'dart:io';

class WinApp extends StatefulWidget {
  const WinApp({super.key});

  @override
  State<WinApp> createState() => _WinAppState();
}

class _WinAppState extends State<WinApp> {
  @override
  void initState() {
    super.initState();
    // Set up exit handler
    ProcessSignal.sigterm.watch().listen((signal) {
      _cleanupAndExit();
    });
  }

  void _cleanupAndExit() {
    try {
      // Try to kill any lingering processes
      if (Platform.isWindows) {
        Process.runSync('taskkill', ['/F', '/IM', 'command_interface.exe']);
      }
    } catch (e) {
      // Ignore errors if process not found
    } finally {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildTime = DateTime.now();
    final formattedTime =
        '${buildTime.year}-${buildTime.month.toString().padLeft(2, '0')}-${buildTime.day.toString().padLeft(2, '0')} '
        '${buildTime.hour.toString().padLeft(2, '0')}:${buildTime.minute.toString().padLeft(2, '0')}';

    // Get current git branch
    String branch = '';
    try {
      final result = Process.runSync('git', ['branch', '--show-current']);
      if (result.exitCode == 0) {
        branch = result.stdout.toString().trim();
      }
    } catch (e) {
      // Ignore errors if git command fails
    }

    final branchInfo = branch.isNotEmpty ? ' [$branch]' : '';

    return MaterialApp(
      title: 'WELL App Prototype v 0.0.2$branchInfo (Built: $formattedTime)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CommandInterface(),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle multiple exit signals
  if (Platform.isWindows) {
    ProcessSignal.sigint.watch().listen((_) => _cleanupAndExit());
    ProcessSignal.sigterm.watch().listen((_) => _cleanupAndExit());
  }

  runApp(const WinApp());
}

void _cleanupAndExit() {
  try {
    // Kill any lingering Dart processes
    Process.runSync('taskkill', ['/F', '/IM', 'dart.exe']);
    Process.runSync('taskkill', ['/F', '/IM', 'command_interface.exe']);
  } catch (e) {
    // Ignore errors if processes not found
  }
  exit(0);
}
