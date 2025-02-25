import '../models/post_debug_entry.dart';

class PostDebugService {
  static final PostDebugService _instance = PostDebugService._internal();
  
  factory PostDebugService() {
    return _instance;
  }
  
  PostDebugService._internal();
  
  final List<PostDebugEntry> _entries = [];
  
  void addEntry(PostDebugEntry entry) {
    _entries.add(entry);
  }
  
  List<PostDebugEntry> getEntries() {
    return List.from(_entries.reversed); // Most recent first
  }
  
  void clear() {
    _entries.clear();
  }
} 