import 'dart:convert';
import '../models/topic.dart';
import '../models/post.dart';
import '../models/conf.dart';

class JsonProcessor {
  static List<Topic> processCommandOutput(String output) {
    // Find the first '[' and last ']'
    final startIndex = output.indexOf('[');
    final endIndex = output.lastIndexOf(']');
    
    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      throw FormatException('Invalid JSON format in command output');
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

  static List<Conf> processConfOutput(String output) {
    // Find the first '[' and last ']'
    final startIndex = output.indexOf('[');
    final endIndex = output.lastIndexOf(']');
    
    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      throw FormatException('Invalid JSON format in command output');
    }

    // Extract the JSON string
    final jsonString = output.substring(startIndex, endIndex + 1);

    try {
      // Parse the JSON string
      final List<dynamic> jsonList = json.decode(jsonString);

      // Convert to List<Conf>
      return jsonList.map((confJson) {
        final conf = Conf(
          name: confJson['name'] as String,
          handle: confJson['handle'] as String,
          title: confJson['title'] as String,
        );

        // Add topics to the conf
        final List<dynamic> topicsJson = confJson['topics'];
        for (var topicJson in topicsJson) {
          final topic = Topic(
            conf: topicJson['conf'] as String,
            handle: topicJson['handle'] as String,
            title: topicJson['title'] as String,
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
            
            post.datetime_iso8601 = postJson['datetime_iso8601'] as String;
            
            final List<dynamic> textList = postJson['text'];
            for (var text in textList) {
              post.appendText(text as String);
            }
            
            topic.addPost(post);
          }
          
          conf.addTopic(topic);
        }

        return conf;
      }).toList();
    } catch (e) {
      throw FormatException('Error parsing JSON: $e');
    }
  }
} 