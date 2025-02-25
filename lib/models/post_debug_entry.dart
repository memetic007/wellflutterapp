class PostDebugEntry {
  final DateTime timestamp;
  final String command;
  final String response;
  final String stderr;
  final String originalText;
  final bool success;

  PostDebugEntry({
    required this.timestamp,
    required this.command,
    required this.response,
    required this.stderr,
    required this.originalText,
    required this.success,
  });
} 