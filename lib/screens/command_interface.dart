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

class CommandInterface extends StatefulWidget {
  const CommandInterface({super.key});

  @override
  State<CommandInterface> createState() => _CommandInterfaceState();
}

class _CommandInterfaceState extends State<CommandInterface> with TickerProviderStateMixin {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _directoryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _useConfs = false;
  
  static const String _directorySaveKey = 'last_directory';
  
  late TabController _tabController;
  List<Topic> _currentTopics = [];
  List<Conf> _currentConfs = [];
  Topic? _selectedTopic;
  Conf? _selectedConf;
  
  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
    _setupKeyboardListeners();
    _createTabController();
  }

  void _createTabController() {
    _tabController = TabController(
      length: _useConfs ? 3 : 2,
      vsync: this,
    );
  }

  void _handleConfsChanged(bool? value) {
    if (value == _useConfs) return;
    
    // Dispose current controller
    _tabController.dispose();
    
    setState(() {
      _useConfs = value ?? false;
      _selectedConf = null;
      _currentTopics = [];
      _selectedTopic = null;
      // Create new controller immediately in setState
      _tabController = TabController(
        length: _useConfs ? 3 : 2,
        vsync: this,
      );
    });
  }

  void _setupKeyboardListeners() {
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
        
        try {
          if (_useConfs) {
            _currentConfs = JsonProcessor.processConfOutput(process.stdout.toString());
            _selectedConf = null;
            _currentTopics = [];
            _selectedTopic = null;
          } else {
            _currentTopics = JsonProcessor.processCommandOutput(process.stdout.toString());
            _selectedTopic = null;
          }
        } catch (e) {
          _outputController.text += 'Error processing data: $e\n\n';
        }
      });
      
      _commandController.clear();
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
                      onChanged: _handleConfsChanged,
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
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: _useConfs 
                  ? const [
                      Tab(text: 'Conferences'),
                      Tab(text: 'Topics'),
                      Tab(text: 'Debug'),
                    ]
                  : const [
                      Tab(text: 'Topics'),
                      Tab(text: 'Debug'),
                    ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _useConfs
                    ? [
                        // Conferences tab
                        ConfView(
                          confs: _currentConfs,
                          onConfSelected: _handleConfSelected,
                        ),
                        // Topics tab
                        _selectedConf == null
                            ? const Center(child: Text('Select a conference to view topics'))
                            : TopicsView(
                                topics: _currentTopics,
                                onTopicSelected: _handleTopicSelected,
                              ),
                        // Debug tab
                        _buildDebugView(),
                      ]
                    : [
                        // Topics tab
                        _selectedTopic == null
                            ? TopicsView(
                                topics: _currentTopics,
                                onTopicSelected: _handleTopicSelected,
                              )
                            : Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => setState(() => _selectedTopic = null),
                                    child: const Text('Back to Topics'),
                                  ),
                                  Expanded(
                                    child: PostsView(topic: _selectedTopic!),
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
    _commandController.dispose();
    _outputController.dispose();
    _directoryController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }
}