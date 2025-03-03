class PostDebugEntry {
  final DateTime timestamp;
  final String originalText;
  final String? widgetSource;
  final bool success;
  final String response;
  final String error;

  PostDebugEntry({
    required this.timestamp,
    required this.originalText,
    this.widgetSource,
    required this.success,
    required this.response,
    required this.error,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'originalText': originalText,
        'widgetSource': widgetSource,
        'success': success,
        'response': response,
        'error': error,
      };

  factory PostDebugEntry.fromJson(Map<String, dynamic> json) => PostDebugEntry(
        timestamp: DateTime.parse(json['timestamp']),
        originalText: json['originalText'],
        widgetSource: json['widgetSource'],
        success: json['success'],
        response: json['response'],
        error: json['error'],
      );
}
