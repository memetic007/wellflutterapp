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
import '../main.dart' show displayLabel;
import '../services/post_debug_service.dart';
import '../widgets/post_debug_dialog.dart';
import 'package:file_picker/file_picker.dart';

// Define intents at file level
class NavigateLeftIntent extends Intent {
  const NavigateLeftIntent();
}

class NavigateRightIntent extends Intent {
  const NavigateRightIntent();
}

class NavigateUpIntent extends Intent {
  const NavigateUpIntent();
}

class NavigateDownIntent extends Intent {
  const NavigateDownIntent();
}

class DeleteCharacterIntent extends Intent {
  const DeleteCharacterIntent();
}

class HomeIntent extends Intent {
  const HomeIntent();
}

class EndIntent extends Intent {
  const EndIntent();
}

class PageUpIntent extends Intent {
  const PageUpIntent();
}

class PageDownIntent extends Intent {
  const PageDownIntent();
}

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
    _checkCredentials();
  }

  void _createTabController() {
    _tabController = TabController(
      length: 4, // Changed to 4 tabs
      vsync: this,
    );
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

        // Update the UI with the loaded topics
        setState(() {
          _currentConfs = confs;
          _allTopics = allTopics;
          _currentTopics = allTopics;
          _selectedConf = null;
          _selectedTopic = null;
          _currentTopicIndex = 0;
          _topicPostsContainerKey.currentState?.resetToStart();

          _outputController.text +=
              '\nSuccessfully loaded ${confs.length} conferences with ${allTopics.length} total topics from well_confs.json';
        });

        await _saveConfsToFile(confs);
      } catch (e) {
        _outputController.text += '\nError loading conference data: $e';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '$displayLabel [${branch}] [Built: ${DateTime.now().toString().substring(0, 16)}]'),
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
                } else if (value == 'debug') {
                  _showDebugDialog(context);
                } else if (value == 'post_debug') {
                  _showPostDebugDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Username/Password'),
                ),
                const PopupMenuItem(
                  value: 'debug',
                  child: Text('Debug View'),
                ),
                const PopupMenuItem(
                  value: 'post_debug',
                  child: Text('Post Debug'),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
        child: Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              // Handle physical keys for numpad
              if (event.physicalKey == PhysicalKeyboardKey.numpad4) {
                _handleArrowKey(LogicalKeyboardKey.arrowLeft);
                return KeyEventResult.handled;
              } else if (event.physicalKey == PhysicalKeyboardKey.numpad6) {
                _handleArrowKey(LogicalKeyboardKey.arrowRight);
                return KeyEventResult.handled;
              } else if (event.physicalKey == PhysicalKeyboardKey.numpad8) {
                _handleArrowKey(LogicalKeyboardKey.arrowUp);
                return KeyEventResult.handled;
              } else if (event.physicalKey == PhysicalKeyboardKey.numpad2) {
                _handleArrowKey(LogicalKeyboardKey.arrowDown);
                return KeyEventResult.handled;
              } else if (event.physicalKey == PhysicalKeyboardKey.numpad7) {
                _handleArrowKey(LogicalKeyboardKey.home);
                return KeyEventResult.handled;
              } else if (event.physicalKey == PhysicalKeyboardKey.numpad1) {
                _handleArrowKey(LogicalKeyboardKey.end);
                return KeyEventResult.handled;
              } else if (event.physicalKey ==
                  PhysicalKeyboardKey.numpadDecimal) {
                _handleDelete();
                return KeyEventResult.handled;
              }

              // Handle logical keys for regular navigation
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _handleArrowKey(LogicalKeyboardKey.arrowLeft);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _handleArrowKey(LogicalKeyboardKey.arrowRight);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _handleArrowKey(LogicalKeyboardKey.arrowUp);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _handleArrowKey(LogicalKeyboardKey.arrowDown);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.home) {
                _handleArrowKey(LogicalKeyboardKey.home);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.end) {
                _handleArrowKey(LogicalKeyboardKey.end);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Directory picker row
              Row(
                children: [
                  const Text(
                    'Directory: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                _directoryController.text.isEmpty 
                                    ? 'No directory selected' 
                                    : _directoryController.text,
                                overflow: TextOverflow.ellipsis,
                                style: _directoryController.text.isEmpty
                                    ? TextStyle(color: Colors.grey[600], fontSize: 14)
                                    : const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () async {
                              String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                              if (selectedDirectory != null) {
                                setState(() {
                                  _directoryController.text = selectedDirectory;
                                  _outputController.text += '\nDirectory changed to: $selectedDirectory\n';
                                });
                              }
                            },
                          ),
                        ],
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
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.text,
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
                              const Spacer(), // Push To Topic Menu button to the right
                              if (_selectedTopic != null) ...[
                                // Only show when a topic is selected
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTopic =
                                          null; // Clear selected topic to return to menu
                                    });
                                  },
                                  child: const Text('To Topic Menu'),
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
                              : TopicPostWidget(
                                  topic: _selectedTopic!,
                                  directory: _directoryController.text.trim(),
                                  credentialsManager: _credentialsManager,
                                  onForgetPressed: () {
                                    setState(() {
                                      _outputController.text +=
                                          '\nForget was pressed for topic: ${_selectedTopic!.handle}';
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Forget was pressed for topic: ${_selectedTopic!.handle}',
                                                    overflow:
                                                        TextOverflow.visible,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            backgroundColor: Colors.green,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                        _outputController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: _outputController
                                                  .text.length),
                                        );
                                      });
                                    });
                                  },
                                ),
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
                                              _topicPostsContainerKey
                                                      .currentState
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
                                              _topicPostsContainerKey
                                                      .currentState
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
                            onNext:
                                _currentTopicIndex < _currentTopics.length - 1
                                    ? () {
                                        setState(() {
                                          _currentTopicIndex++;
                                        });
                                      }
                                    : null,
                            onForgetPressed: () {
                              final topic = _currentTopics[_currentTopicIndex];
                              setState(() {
                                _outputController.text +=
                                    '\nForget was pressed for topic: ${topic.handle}';
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.white),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Forget was pressed for topic: ${topic.handle}',
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  _outputController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: _outputController.text.length),
                                  );
                                });
                              });
                            },
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

  void _handleArrowKey(LogicalKeyboardKey key) {
    final TextEditingController controller = _commandController;
    final selection = controller.selection;

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        if (selection.start > 0) {
          controller.selection = TextSelection.collapsed(
            offset: selection.start - 1,
          );
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (selection.start < controller.text.length) {
          controller.selection = TextSelection.collapsed(
            offset: selection.start + 1,
          );
        }
        break;
      case LogicalKeyboardKey.home:
        controller.selection = const TextSelection.collapsed(offset: 0);
        break;
      case LogicalKeyboardKey.end:
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        break;
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
        // Handle these if needed
        break;
    }
  }

  KeyEventResult _handleDelete() {
    final selection = _commandController.selection;
    final text = _commandController.text;

    // Check if we have a valid selection and text
    if (selection.start < 0 || selection.start >= text.length) {
      return KeyEventResult.handled;
    }

    if (selection.start < _commandController.text.length) {
      final newText =
          text.replaceRange(selection.start, selection.start + 1, '');
      _commandController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
    return KeyEventResult.handled;
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debug Output',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_outputController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PostDebugDialog(),
    );
  }
}
