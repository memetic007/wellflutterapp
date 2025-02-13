import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/json_processor.dart';
import '../models/topic.dart';
import '../models/conf.dart';
import '../widgets/topics_view.dart';
import '../widgets/posts_view.dart';
import '../widgets/conf_view.dart';
import '../utils/credentials_manager.dart';
import '../widgets/login_dialog.dart';
import '../widgets/topic_posts_container.dart';
import '../widgets/topic_post_widget.dart';

class CommandInterface extends StatefulWidget {
  const CommandInterface({super.key});

  @override
  State<CommandInterface> createState() => _CommandInterfaceState();
}

class _CommandInterfaceState extends State<CommandInterface>
    with TickerProviderStateMixin {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _directoryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const String _directorySaveKey = 'last_directory';
  static const String _commandSaveKey = 'last_command';

  late TabController _tabController;
  List<Topic> _currentTopics = [];
  List<Conf> _currentConfs = [];
  Topic? _selectedTopic;
  Conf? _selectedConf;

  final _credentialsManager = CredentialsManager();
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
    _loadSavedCommand();
    _setupKeyboardListeners();
    _createTabController();
    _checkCredentials();
  }

  void _createTabController() {
    _tabController = TabController(
      length: 4, // Changed to 4 tabs
      vsync: this,
    );
  }

  void _setupKeyboardListeners() {
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        final isControlPressed = HardwareKeyboard.instance.isControlPressed;

        if (event.logicalKey == LogicalKeyboardKey.numpad1 &&
            isControlPressed) {
          _commandController.selection = TextSelection.fromPosition(
            TextPosition(offset: _commandController.text.length),
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.numpad7 &&
            isControlPressed) {
          _commandController.selection =
              const TextSelection.collapsed(offset: 0);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.numpadDecimal) {
          final selection = _commandController.selection;
          if (selection.start < _commandController.text.length) {
            final text = _commandController.text;
            final newText =
                text.replaceRange(selection.start, selection.start + 1, '');
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

  Future<void> _loadSavedCommand() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCommand = prefs.getString(_commandSaveKey);
    if (savedCommand != null) {
      setState(() {
        _commandController.text = savedCommand;
      });
    }
  }

  Future<void> _saveCommand() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_commandSaveKey, _commandController.text.trim());
  }

  Future<void> _checkCredentials() async {
    if (!await _credentialsManager.hasCredentials()) {
      await _showLoginDialog();
    } else {
      _currentUsername = await _credentialsManager.getUsername();
      setState(() {});
    }
  }

  Future<void> _showLoginDialog() async {
    final currentUsername = await _credentialsManager.getUsername();
    final currentPassword = await _credentialsManager.getPassword();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: currentUsername != null,
      builder: (context) => LoginDialog(
        initialUsername: currentUsername,
        initialPassword: currentPassword,
      ),
    );

    if (result != null) {
      await _credentialsManager.setCredentials(
        result['username']!,
        result['password']!,
      );
      setState(() {
        _currentUsername = result['username'];
      });
    } else if (currentUsername == null) {
      // If no credentials exist and user cancelled, show dialog again
      await _showLoginDialog();
    }
  }

  Future<void> _executeCommand() async {
    try {
      final username = await _credentialsManager.getUsername();
      final password = await _credentialsManager.getPassword();

      if (username == null || password == null) {
        await _showLoginDialog();
        return;
      }

      final dir = _directoryController.text.trim();
      final cmd = _commandController.text.trim();
      if (cmd.isEmpty) return;

      if (dir.isNotEmpty) {
        await _saveDirectory();
      }

      await _saveCommand();

      // Always use -conf mode
      const makeObjectsCommand = 'python makeobjects2json.py -conf';

      // Construct the Python command with the user input
      final pythonCommand =
          'python remoteexec.py --username $username --password $password -- "extract $cmd" | python extract2json.py | $makeObjectsCommand';

      final fullCommand =
          dir.isNotEmpty ? 'cd "$dir" ; $pythonCommand' : pythonCommand;

      final process = await Process.run(
        'powershell.exe',
        ['-Command', fullCommand],
        runInShell: true,
      );

      setState(() {
        _outputController.clear();
        _outputController.text += 'PS> $fullCommand\n';
        _outputController.text += process.stdout.toString();
        if (process.stderr.toString().isNotEmpty) {
          _outputController.text += process.stderr.toString();
        }
        _outputController.text += '\n';

        try {
          _currentConfs =
              JsonProcessor.processConfOutput(process.stdout.toString());
          _selectedConf = null;
          _currentTopics = [];
          _selectedTopic = null;
        } catch (e) {
          _outputController.text += 'Error processing data: $e\n\n';
        }
      });
    } catch (e) {
      setState(() {
        _outputController.text += 'PS> ${_commandController.text}\n';
        _outputController.text += 'Error: $e\n\n';
      });
    }
  }

  void _handleTopicSelected(Topic topic) {
    setState(() {
      _selectedTopic = topic;
    });
  }

  void _handleConfSelected(Conf conf) {
    setState(() {
      _selectedConf = conf;
      _currentTopics = conf.topics;
      _tabController.animateTo(1); // Switch to Topics tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WELL App Prototype v 0.0.2'),
        actions: [
          if (_currentUsername != null)
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _currentUsername!,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showLoginDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Username/Password'),
                ),
              ],
            ),
        ],
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
                const Text(
                  'Directory: ',
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      decoration: InputDecoration(
                        hintText: 'Enter command...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _commandController.clear();
                          },
                        ),
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
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Conferences'),
                Tab(text: 'Topics Menu'),
                Tab(text: 'All Topics'),
                Tab(text: 'Debug'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Conferences tab
                  ConfView(
                    confs: _currentConfs,
                    onConfSelected: _handleConfSelected,
                  ),
                  // Topics Menu tab
                  _selectedConf == null
                      ? const Center(
                          child: Text('Select a conference to view topics'))
                      : _selectedTopic == null
                          ? TopicsView(
                              topics: _currentTopics,
                              onTopicSelected: _handleTopicSelected,
                            )
                          : TopicPostWidget(topic: _selectedTopic!),
                  // All Topics tab
                  _selectedConf == null
                      ? const Center(
                          child: Text('Select a conference to view topics'))
                      : TopicPostsContainer(topics: _currentTopics),
                  // Debug tab
                  _buildDebugView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugView() {
    return ConstrainedBox(
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
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _outputController.dispose();
    _directoryController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
