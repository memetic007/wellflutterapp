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
import '../services/well_api_service.dart';
import '../widgets/text_editor_with_nav.dart';

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
  final FocusNode _focusNode = FocusNode();

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

  final _apiService = WellApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    _loadSavedCommand();
    _checkCredentials();
  }

  @override
  void didUpdateWidget(CommandInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure TabController is updated on hot reload
    if (_tabController.length != 3) {
      _tabController.dispose();
      _tabController = TabController(
        length: 3,
        vsync: this,
      );
    }
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

  Future<void> _executeCommand(String cmd) async {
    try {
      final username = await _credentialsManager.getUsername();
      final password = await _credentialsManager.getPassword();

      if (username == null || password == null) {
        throw Exception('Username or password not found');
      }

      // First ensure we have a connection
      if (!_apiService.isConnected) {
        final connectResult = await _apiService.connect(username, password);
        if (!connectResult['success']) {
          throw Exception('Failed to connect: ${connectResult['error']}');
        }
      }

      // Now execute the command
      final response = await _apiService.processCommand({
        'command': cmd,
      });

      setState(() {
        if (response['success']) {
          _outputController.text += '\n> $cmd\n';

          // Handle the conference list if available
          if (response['conflist'] != null && response['conflist'].isNotEmpty) {
            _outputController.text += '\nAvailable conferences:\n';
            for (final conf in response['conflist']) {
              _outputController.text += '- $conf\n';
            }
          }

          // Handle the main response (JSON formatted conference data)
          if (response['response'].isNotEmpty) {
            try {
              final jsonData = response['response'];
              _processCommandResponse(jsonData);
            } catch (e) {
              _outputController.text += '\nError processing response: $e\n';
              // Still show the raw response for debugging
              _outputController.text +=
                  '\nRaw Response:\n${response['response']}\n';
            }
          }

          // Show any errors
          if (response['error'].isNotEmpty) {
            _outputController.text += '\nErrors:\n${response['error']}';
          }

          // Switch to conferences tab after successful response
          _tabController.animateTo(0); // Index 0 is the conferences tab

          // Save the command
          _saveCommand();
        } else {
          _outputController.text += '\nError: ${response['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _outputController.text += '\nError: $e';
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/sweeperimage.jpeg',
              height: 48, // Doubled from 24 to 48 pixels
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8), // Add some spacing between image and text
            const Text('WELL Sweeper'),
          ],
        ),
        actions: [
          if (_currentUsername != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                    } else if (value == 'about') {
                      _showAboutDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'about',
                      child: Text('About'),
                    ),
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
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
                  child: TextButton.icon(
                    onPressed: _handleConnect,
                    icon: const Icon(Icons.power, size: 16),
                    label: const Text('Connect'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 24),
                    ),
                  ),
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
              // Add Get Conf List button
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _getConfList,
                      child: const Text('Get Conf List'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showEditConfListDialog,
                      child: const Text('Edit Conf List'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showCommandDialog(context),
                      child: const Text('Custom'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'Conferences'),
                  Tab(text: _topicsMenuLabel),
                  Tab(text: _allTopicsLabel),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_selectedTopic == null) ...[
                                // Mode 1: Topic List View
                                ElevatedButton(
                                  onPressed: () => _showButtonPressed(
                                      context, 'createNewTopicPressed'),
                                  child: const Text('New Topic'),
                                ),
                                if (_selectedConf != null) ...[
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _handleConfSelected(null),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('All Confs'),
                                  ),
                                ],
                              ] else ...[
                                // Mode 2: Posts View
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTopic =
                                          null; // Return to topic list
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Topic Menu'),
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
                                ? _handlePreviousPressed
                                : null,
                            onNext:
                                _currentTopicIndex < _currentTopics.length - 1
                                    ? _handleNextPressed
                                    : null,
                            onForgetPressed: _handleForgetPressed,
                            credentialsManager: _credentialsManager,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commandController.dispose();
    _outputController.dispose();
    _focusNode.dispose();

    // Clear any stored state
    _currentTopics.clear();
    _currentConfs.clear();
    _allTopics.clear();

    if (_topicPostsContainerKey.currentState != null) {
      _topicPostsContainerKey.currentState!.dispose();
    }

    super.dispose();
  }

  Future<void> _loadConfsFromFile() async {
    try {
      final dir = '';
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
      builder: (dialogContext) => Dialog(
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
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _outputController.clear();
                          setState(() {}); // Trigger rebuild after clearing
                          Navigator.of(dialogContext)
                              .pop(); // Close dialog after clearing
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
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

  void _processCommandResponse(dynamic response) {
    try {
      // Handle different response formats
      dynamic jsonData;

      if (response is Map<String, dynamic>) {
        // If response is already a Map, extract the 'response' field
        final responseStr = response['response'];
        if (responseStr is String) {
          jsonData = jsonDecode(responseStr);
        } else {
          jsonData = responseStr;
        }
      } else if (response is String) {
        // If response is a String, decode it directly
        jsonData = jsonDecode(response);
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }

      print('Decoded JSON data: $jsonData');

      // Process the conferences and topics
      List<Conf> processedConfs = [];
      List<Topic> allTopics = [];

      // Check if the response is a list of conferences
      if (jsonData is List) {
        for (var confData in jsonData) {
          // Create a Conf object from the JSON data
          final conf = Conf.fromJson(confData);

          // Always add the conference, even if it has no topics
          processedConfs.add(conf);

          // Add topics to the allTopics list if there are any
          if (conf.topics.isNotEmpty) {
            allTopics.addAll(conf.topics);
          }

          print(
              'Processed conference: ${conf.name} with ${conf.topics.length} topics');
        }
      }

      // Update the state with the current conferences and topics
      setState(() {
        _currentConfs = processedConfs;
        _allTopics = allTopics;
        _currentTopics = allTopics;

        // Output detailed information about loaded conferences
        int confsWithTopics =
            processedConfs.where((c) => c.topics.isNotEmpty).length;
        int confsWithoutTopics = processedConfs.length - confsWithTopics;

        _outputController.text +=
            '\nLoaded ${processedConfs.length} conferences:';
        _outputController.text += '\n - $confsWithTopics with topics';
        _outputController.text +=
            '\n - $confsWithoutTopics with empty topic lists';

        // List the conference names
        _outputController.text +=
            '\nConferences: ${processedConfs.map((c) => c.name).join(', ')}';

        // Display the first topic if any are available
        if (allTopics.isNotEmpty) {
          _selectedTopic = allTopics.first;
        } else {
          _selectedTopic = null;
        }
      });
    } catch (e) {
      setState(() {
        _outputController.text += '\nError processing response: $e';
      });
    }
  }

  void _handlePreviousPressed() {
    setState(() {
      if (_currentTopicIndex > 0) {
        _currentTopicIndex--;
      }
    });
  }

  void _handleNextPressed() {
    setState(() {
      if (_currentTopicIndex < _currentTopics.length - 1) {
        _currentTopicIndex++;
      }
    });
  }

  void _handleForgetPressed() {
    final topic = _currentTopics[_currentTopicIndex];
    setState(() {
      _outputController.text +=
          '\nForget was pressed for topic: ${topic.handle}';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
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
            width: MediaQuery.of(context).size.width * 0.8,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _outputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _outputController.text.length),
        );
      });
    });
  }

  // Add this method to handle the Get Conf List button press
  Future<void> _getConfList() async {
    try {
      final username = await _credentialsManager.getUsername();
      final password = await _credentialsManager.getPassword();

      if (username == null || password == null) {
        throw Exception('Username or password not found');
      }

      // Ensure we have a connection
      if (!_apiService.isConnected) {
        final connectResult = await _apiService.connect(username, password);
        if (!connectResult['success']) {
          throw Exception('Failed to connect: ${connectResult['error']}');
        }
      }

      // Get the conference list
      final response = await _apiService.processCommand({
        'conflist': true, // This tells the server to return the full conf list
      });

      setState(() {
        if (response['success']) {
          _outputController.text += '\n> Get Conference List\n';

          // Handle the conference list
          if (response['conflist'] != null && response['conflist'].isNotEmpty) {
            _outputController.text += '\nAvailable conferences:\n';
            for (final conf in response['conflist']) {
              _outputController.text += '- $conf\n';
            }
          }

          // Handle any additional output
          if (response['response'].isNotEmpty) {
            try {
              final jsonData = response['response'];
              _processCommandResponse(jsonData);
            } catch (e) {
              _outputController.text += '\nError processing response: $e\n';
              _outputController.text +=
                  '\nRaw Response:\n${response['response']}\n';
            }
          }

          // Show any errors
          if (response['error'].isNotEmpty) {
            _outputController.text += '\nErrors:\n${response['error']}';
          }

          // Switch to conferences tab after successful response
          _tabController.animateTo(0); // Index 0 is the conferences tab
        } else {
          _outputController.text += '\nError: ${response['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _outputController.text += '\nError: $e';
      });
    }
  }

  Future<void> _handleConnect() async {
    try {
      final username = await _credentialsManager.getUsername();
      final password = await _credentialsManager.getPassword();

      if (username == null || password == null) {
        throw Exception('Username or password not found');
      }

      setState(() {
        _outputController.text += '\n> Connecting as $username...';
      });

      final connectResult = await _apiService.connect(username, password);

      setState(() {
        if (connectResult['success']) {
          _outputController.text += '\nConnection successful!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Connected successfully'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              width: MediaQuery.of(context).size.width * 0.3,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _outputController.text +=
              '\nConnection failed: ${connectResult['error']}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Connection failed: ${connectResult['error']}'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              width: MediaQuery.of(context).size.width * 0.3,
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _outputController.text += '\nError: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          width: MediaQuery.of(context).size.width * 0.3,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showEditConfListDialog() async {
    final result = await _apiService.getCfList();
    if (!result['success']) {
      _showError('Failed to get conference list: ${result['error']}');
      return;
    }

    // Fix the type casting issue by properly converting List<dynamic> to List<String>
    final List<dynamic> dynamicList = result['cflist'] as List<dynamic>;
    final List<String> currentList =
        dynamicList.map((item) => item.toString()).toList();

    final TextEditingController textController = TextEditingController(
      text: currentList.join('\n'),
    );

    final saveResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Conference List'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter conferences, one per line',
                    contentPadding: EdgeInsets.all(12),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final List<String> conferenceList = textController.text
                  .split('\n')
                  .where((line) => line.trim().isNotEmpty)
                  .toList();

              final result = await _apiService.putCfList(conferenceList);

              if (result['success']) {
                // IMPORTANT: Remove this dialog that's causing the extraneous popup
                // DO NOT show another dialog after saving successfully
                Navigator.of(context).pop(true);

                // Show a snackbar instead
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Conference list saved successfully'),
                    behavior: SnackBarBehavior.floating,
                    width: MediaQuery.of(context).size.width * 0.3,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text('Failed to save: ${result['error']}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saveResult == true) {
      // Refresh the UI if needed
      _refreshConferences();
    }
  }

  void _showAboutDialog(BuildContext context) {
    String branch = '';
    try {
      final result = Process.runSync('git', ['branch', '--show-current']);
      if (result.exitCode == 0) {
        branch = result.stdout.toString().trim();
      }
    } catch (e) {
      // Ignore errors if git command fails
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About WELL App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayLabel'),
            if (branch.isNotEmpty) Text('Branch: $branch'),
            Text('Built: ${DateTime.now().toString().substring(0, 16)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom Command'),
        content: SizedBox(
          width: 600, // Set a reasonable width for the dialog
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextEditorWithNav(
                        controller: _commandController,
                        style: const TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 14,
                        ),
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _commandController.clear();
              setState(() {});
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () async {
              await _executeCommand(_commandController.text.trim());
              Navigator.of(dialogContext)
                  .pop(); // Close dialog after command execution
            },
            child: const Text('Submit'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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

  void _refreshConferences() {
    // Implement the logic to refresh the conferences
  }
}
