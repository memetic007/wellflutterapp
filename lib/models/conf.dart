import 'topic.dart';

class Conf {
  final String name;
  final String handle;
  final String title;
  final int newTopicCount;
  final List<Topic> topics;

  Conf({
    required this.name,
    required this.handle,
    required this.title,
    required this.newTopicCount,
    required this.topics,
  });

  // Factory constructor for empty conference
  factory Conf.empty() {
    return Conf(
      name: "",
      handle: "",
      title: "",
      newTopicCount: 0,
      topics: [],
    );
  }

  void addTopic(Topic topic) {
    topics.add(topic);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'handle': handle,
      'title': title,
      'newTopicCount': newTopicCount,
      'topics': topics.map((topic) => topic.toJson()).toList(),
    };
  }

  // Add JSON deserialization method
  factory Conf.fromJson(Map<String, dynamic> json) {
    // Get topics list
    List<Topic> allTopics = (json['topics'] as List)
        .map((topicJson) => Topic.fromJson(topicJson))
        .toList();

    // Get the conference name either from the main json or from the first topic's conf
    String confName = json['name']?.toString() ??
        (allTopics.isNotEmpty ? allTopics.first.conf : '');

    // Filter topics to only include those matching this conference
    List<Topic> confTopics =
        allTopics.where((topic) => topic.conf == confName).toList();

    return Conf(
      name: confName,
      handle: json['handle']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      newTopicCount: json['newTopicCount'] as int? ?? 0,
      topics: confTopics,
    );
  }

  // Add a method to split conferences by their conf values
  static List<Conf> splitByConf(Map<String, dynamic> json) {
    // Get all topics from the JSON, handling both direct topics and nested topics
    List<Topic> allTopics = [];

    // If we have a topics array directly in the JSON
    if (json['topics'] != null) {
      allTopics.addAll((json['topics'] as List)
          .map((topicJson) => Topic.fromJson(topicJson)));
    }

    // Get unique conference names from topics
    Set<String> uniqueConfs = allTopics.map((topic) => topic.conf).toSet();

    // Create a conference for each unique conf value
    return uniqueConfs.map((confName) {
      final confTopics =
          allTopics.where((topic) => topic.conf == confName).toList();
      return Conf(
        name: confName,
        handle: '', // Handle might not be available in this context
        title: '', // Conference title might not be available
        newTopicCount: 0, // Default to 0 if not available
        topics: confTopics,
      );
    }).toList();
  }
}
