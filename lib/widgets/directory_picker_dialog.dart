import 'package:flutter/material.dart';
import 'dart:io';

class DirectoryPickerDialog extends StatefulWidget {
  final String initialDirectory;
  
  const DirectoryPickerDialog({
    super.key, 
    this.initialDirectory = '',
  });

  @override
  State<DirectoryPickerDialog> createState() => _DirectoryPickerDialogState();
}

class _DirectoryPickerDialogState extends State<DirectoryPickerDialog> {
  late String _currentPath;
  List<FileSystemEntity> _entities = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _error = '';
  
  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialDirectory.isNotEmpty 
        ? widget.initialDirectory 
        : Directory.current.path;
    _loadDirectory(_currentPath);
  }
  
  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        
        // Sort: directories first, then files
        entities.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
        
        setState(() {
          _currentPath = path;
          _entities = entities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Directory does not exist';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading directory: $e';
        _isLoading = false;
      });
    }
  }
  
  void _navigateUp() {
    final parent = Directory(_currentPath).parent;
    _loadDirectory(parent.path);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Select Directory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentPath,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Go up one level',
                    onPressed: _navigateUp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red[100],
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _entities.length,
                        itemBuilder: (context, index) {
                          final entity = _entities[index];
                          final isDirectory = entity is Directory;
                          final name = entity.path.split(Platform.pathSeparator).last;
                          
                          if (isDirectory) {
                            return ListTile(
                              leading: const Icon(Icons.folder, color: Colors.amber),
                              title: Text(name),
                              onTap: () => _loadDirectory(entity.path),
                            );
                          } else {
                            return ListTile(
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(name),
                              enabled: false,
                            );
                          }
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_currentPath),
                  child: const Text('Select This Directory'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 