import '../models/post_debug_entry.dart';
import 'well_api_service.dart';

class PostDebugService {
  static final PostDebugService _instance = PostDebugService._internal();

  factory PostDebugService() {
    return _instance;
  }

  PostDebugService._internal();

  final List<PostDebugEntry> _entries = [];
  final _apiService = WellApiService();

  Future<PostDebugEntry> processText(String text, {String? source}) async {
    final result = await _apiService.processText(text, source: source);

    final entry = PostDebugEntry(
      timestamp: DateTime.now(),
      originalText: text,
      widgetSource: source,
      success: result['success'],
      response: result['response'].toString(),
      error: result['error'],
    );

    _entries.insert(0, entry);
    return entry;
  }

  List<PostDebugEntry> getEntries() => List.unmodifiable(_entries);

  void clear() => _entries.clear();

  void addDebugEntry(PostDebugEntry entry) {
    _entries.add(entry);
  }
}
