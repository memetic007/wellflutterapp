import 'dart:convert';
import '../models/topic.dart';
import '../models/post.dart';
import '../models/conf.dart';
import 'dart:io';

class JsonProcessor {
  static List<Topic> processCommandOutput(String output) {
    // Find the first '[' and last ']'
    final startIndex = output.indexOf('[');
    final endIndex = output.lastIndexOf(']');

    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      throw const FormatException('Invalid JSON format in command output');
    }

    // Extract the JSON string
    final jsonString = output.substring(startIndex, endIndex + 1);

    try {
      // Parse the JSON string
      final List<dynamic> jsonList = json.decode(jsonString);

      // Convert to List<Topic>
      return jsonList.map((topicJson) {
        final topic = Topic(
          conf: topicJson['conf'] as String,
          handle: topicJson['handle'] as String,
          title: topicJson['title'] as String,
          number: topicJson['number'] as int? ?? 0,
          lastPost: topicJson['lastPost'] as int? ?? 0,
          lastPostTime: topicJson['lastPostTime'] as String? ?? '',
          lastPoster: topicJson['lastPoster'] as String? ?? '',
          url: topicJson['url'] as String? ?? '',
        );

        // Add posts to the topic
        final List<dynamic> postsJson = topicJson['posts'];
        for (var postJson in postsJson) {
          final post = Post(
            handle: postJson['handle'] as String,
            datetime: postJson['datetime'] as String,
            username: postJson['username'] as String,
            pseud: postJson['pseud'] as String,
          );

          // Set ISO datetime
          post.datetime_iso8601 = postJson['datetime_iso8601'] as String;

          // Add text entries
          final List<dynamic> textList = postJson['text'];
          for (var text in textList) {
            post.appendText(text as String);
          }

          topic.addPost(post);
        }

        return topic;
      }).toList();
    } catch (e) {
      throw FormatException('Error parsing JSON: $e');
    }
  }

  static Topic _createTopic(Map<String, dynamic> json) {
    return Topic(
      conf: json['conf'] as String,
      handle: json['handle'] as String,
      title: json['title'] as String,
      number: json['number'] as int? ?? 0,
      lastPost: json['lastPost'] as int? ?? 0,
      lastPostTime: json['lastPostTime'] as String? ?? '',
      lastPoster: json['lastPoster'] as String? ?? '',
      url: json['url'] as String? ?? '',
      posts: (json['posts'] as List?)
          ?.map((p) => Post.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<Topic> getTopics(String directory, String confName) {
    final file = File('$directory/$confName.json');
    if (!file.existsSync()) return [];

    final jsonString = file.readAsStringSync();
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => _createTopic(json as Map<String, dynamic>))
        .toList();
  }

  static List<Conf> processConfOutput(String output) {
    // Find the first '[' and last ']'
    final startIndex = output.indexOf('[');
    final endIndex = output.lastIndexOf(']');

    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      throw const FormatException('Invalid JSON format in command output');
    }

    // Extract the JSON string
    final jsonString = output.substring(startIndex, endIndex + 1);

    try {
      // Parse the JSON string
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((confJson) => Conf.fromJson(confJson)).toList();
    } catch (e) {
      throw FormatException('Error parsing JSON: $e');
    }
  }

  static Future<List<Topic>> getTopicsAsync(
      String directory, String confName) async {
    final file = File('$directory/${confName}_topics.json');
    if (!await file.exists()) {
      return [];
    }
    final jsonString = await file.readAsString();
    return processCommandOutput(jsonString);
  }

  static Future<List<Conf>> getConfs(String directory) async {
    final file = File('$directory/confs.json');
    if (!await file.exists()) {
      return [];
    }
    final jsonString = await file.readAsString();
    return processConfOutput(jsonString);
  }
}
