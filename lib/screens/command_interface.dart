import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/json_processor.dart';
import '../models/topic.dart';
import '../models/conf.dart';
import '../widgets/topics_view.dart';
import '../widgets/conf_view.dart';
import '../utils/credentials_manager.dart';
import '../widgets/login_dialog.dart';
import '../widgets/topic_posts_container.dart';
import '../widgets/topic_post_widget.dart';
import 'dart:convert';

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

  List<Topic> _allTopics = [];

  String get _topicsMenuLabel => _selectedConf == null
      ? 'Topics Menu (all)'
      : 'Topics Menu (${_selectedConf!.name})';

  String get _allTopicsLabel => _selectedConf == null
      ? 'New Posts (all)'
      : 'All Posts (${_selectedConf!.name})';

  int _currentTopicIndex = 0;

  final _topicPostsContainerKey = GlobalKey<TopicPostsContainerState>();

  @override
  void initState() {
    super.initState();
    _createTabController();
    _loadSavedDirectory();
    _loadSavedCommand();
    _setupKeyboardListeners();
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
      final directory = Directory(savedDirectory);
      if (await directory.exists()) {
        setState(() {
          _directoryController.text = savedDirectory;
        });
        await _loadConfsFromFile();
      }
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
      });

      // Process the output once
      try {
        final confs =
            JsonProcessor.processConfOutput(process.stdout.toString());

        // Extract all topics from all confs
        final allTopics = <Topic>[];
        for (var conf in confs) {
          allTopics.addAll(conf.topics);
        }

        setState(() {
          _currentConfs = confs;
          _selectedConf = null;
          _selectedTopic = null;
          _allTopics = allTopics;
          _currentTopics = allTopics;
          _currentTopicIndex = 0;
          _topicPostsContainerKey.currentState?.resetToStart();

          _outputController.text +=
              '\nLoaded ${confs.length} conferences with ${allTopics.length} total topics';
        });

        await _saveConfsToFile(confs); // Save after successful processing

        if (cmd == 'l') {
          _tabController.animateTo(0);
        }
      } catch (e) {
        _outputController.text += 'Error processing data: $e\n\n';
      }
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

  void _handleConfSelected(Conf? conf) {
    _outputController.text += '\nConference selected: ${conf?.name ?? "null"}';
    setState(() {
      _selectedConf = conf;
      _selectedTopic = null;
      if (conf != null) {
        _currentTopics = conf.topics; // Use topics directly from conf
        _outputController.text +=
            '\nShowing ${_currentTopics.length} topics from ${conf.name}';
        _tabController
            .animateTo(1); // Switch to Topics Menu tab when conf selected
      } else {
        _currentTopics = _allTopics;
        _outputController.text +=
            '\nShowing all ${_currentTopics.length} topics';
      }
    });
  }

  void _showButtonPressed(BuildContext context, String buttonName) {
    String message;
    switch (buttonName) {
      case 'createNewTopicPressed':
        message = 'New Topic button was pressed';
        break;
      case 'topicsMenuTabRefresh':
        message = 'Topics Menu Refresh button was pressed';
        break;
      // ... other cases ...
      default:
        message = '$buttonName button was pressed';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              tabs: [
                const Tab(text: 'Conferences'),
                Tab(text: _topicsMenuLabel),
                Tab(text: _allTopicsLabel),
                const Tab(text: 'Debug'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Conferences tab
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showButtonPressed(
                                  context, 'conferencesTabRefresh'),
                              child: const Text('Refresh'),
                            ),
                            if (_selectedConf != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleConfSelected(null),
                                child: const Text('All Confs'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: ConfView(
                          confs: _currentConfs,
                          onConfSelected: _handleConfSelected,
                        ),
                      ),
                    ],
                  ),
                  // Topics Menu tab
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showButtonPressed(
                                  context, 'topicsMenuTabRefresh'),
                              child: const Text('Refresh'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showButtonPressed(
                                  context, 'createNewTopicPressed'),
                              child: const Text('New Topic'),
                            ),
                            if (_selectedConf != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleConfSelected(null),
                                child: const Text('All Confs'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedTopic == null
                            ? TopicsView(
                                topics: _currentTopics,
                                onTopicSelected: _handleTopicSelected,
                              )
                            : TopicPostWidget(topic: _selectedTopic!),
                      ),
                    ],
                  ),
                  // All Posts tab
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showButtonPressed(
                                  context, 'allPostsTabRefresh'),
                              child: const Text('Refresh'),
                            ),
                            if (_selectedConf != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleConfSelected(null),
                                child: const Text('All Confs'),
                              ),
                            ],
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _topicPostsContainerKey
                                                .currentState?.isScrolling !=
                                            true
                                        ? () {
                                            final container =
                                                _topicPostsContainerKey
                                                    .currentState;
                                            if (container != null) {
                                              container.scrollToIndex(0);
                                            }
                                          }
                                        : null,
                                    child: const Text('Home'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _currentTopicIndex > 0 &&
                                            _topicPostsContainerKey.currentState
                                                    ?.isScrolling !=
                                                true
                                        ? () {
                                            final container =
                                                _topicPostsContainerKey
                                                    .currentState;
                                            if (container != null) {
                                              container.scrollToPrevious();
                                            }
                                          }
                                        : null,
                                    child: const Text('Previous'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text(
                                      _topicPostsContainerKey.currentState
                                              ?.currentPositionText ??
                                          'Topic 1 of ${_currentTopics.length}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _currentTopicIndex <
                                                _currentTopics.length - 1 &&
                                            _topicPostsContainerKey.currentState
                                                    ?.isScrolling !=
                                                true
                                        ? () {
                                            final container =
                                                _topicPostsContainerKey
                                                    .currentState;
                                            if (container != null) {
                                              container.scrollToNext();
                                            }
                                          }
                                        : null,
                                    child: const Text('Next'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _topicPostsContainerKey
                                                .currentState?.isScrolling !=
                                            true
                                        ? () {
                                            final container =
                                                _topicPostsContainerKey
                                                    .currentState;
                                            if (container != null) {
                                              container.scrollToIndex(
                                                  _currentTopics.length - 1);
                                            }
                                          }
                                        : null,
                                    child: const Text('End'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TopicPostsContainer(
                          key: _topicPostsContainerKey,
                          topics: _currentTopics,
                          onPrevious: _currentTopicIndex > 0
                              ? () {
                                  setState(() {
                                    _currentTopicIndex--;
                                  });
                                }
                              : null,
                          onNext: _currentTopicIndex < _currentTopics.length - 1
                              ? () {
                                  setState(() {
                                    _currentTopicIndex++;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
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
    // Dispose controllers
    _commandController.dispose();
    _outputController.dispose();
    _directoryController.dispose();
    _focusNode.dispose();
    _tabController.dispose();

    // Clear any stored state
    _currentTopics.clear();
    _currentConfs.clear();
    _allTopics.clear();

    // Ensure the key is disposed
    if (_topicPostsContainerKey.currentState != null) {
      _topicPostsContainerKey.currentState!.dispose();
    }

    // Force cleanup of any lingering processes
    if (Platform.isWindows) {
      try {
        Process.runSync('taskkill', ['/F', '/IM', 'dart.exe']);
      } catch (e) {
        // Ignore errors if process not found
      }
    }

    // Call parent dispose
    super.dispose();
  }

  Future<void> _saveConfsToFile(List<Conf> confs) async {
    try {
      final dir = _directoryController.text.trim();
      if (dir.isEmpty) return;

      final file = File('$dir/well_confs.json');
      final jsonList = confs.map((conf) => conf.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      _outputController.text += '\nSaved conference data to well_confs.json';
    } catch (e) {
      _outputController.text += '\nError saving conference data: $e';
    }
  }

  Future<void> _loadConfsFromFile() async {
    try {
      final dir = _directoryController.text.trim();
      if (dir.isEmpty) {
        _outputController.text += '\nDirectory is empty, cannot load confs';
        return;
      }

      final file = File('$dir/well_confs.json');
      if (!await file.exists()) {
        _outputController.text += '\nwell_confs.json does not exist in $dir';
        return;
      }

      _outputController.text += '\nReading well_confs.json...';
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;
      final confs = jsonList.map((json) => Conf.fromJson(json)).toList();

      // Extract all topics from all confs
      final allTopics = <Topic>[];
      for (var conf in confs) {
        allTopics.addAll(conf.topics);
      }

      // First update the data
      setState(() {
        _currentConfs = confs;
        _allTopics = allTopics;
        _currentTopics = allTopics;
        _currentTopicIndex = 0;
      });

      // Force a rebuild to ensure the container is created
      await Future.delayed(Duration.zero);

      // Then update the UI if we're still mounted
      if (mounted) {
        // Force the container to show the first topic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_topicPostsContainerKey.currentState != null) {
            _topicPostsContainerKey.currentState!.resetToStart();
          }
        });
      }

      _outputController.text +=
          '\nSuccessfully loaded ${confs.length} conferences with ${allTopics.length} total topics from well_confs.json';
    } catch (e) {
      _outputController.text += '\nError loading conference data: $e';
    }
  }
}
