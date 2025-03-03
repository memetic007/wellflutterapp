import 'topic.dart';

class Conf {
  final String name;
  final String title;
  final List<Topic> topics;

  Conf({
    required this.name,
    required this.title,
    required this.topics,
  });

  // Factory constructor for empty conference
  factory Conf.empty() {
    return Conf(
      name: "",
      title: "",
      topics: [],
    );
  }

  void addTopic(Topic topic) {
    topics.add(topic);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'topics': topics.map((topic) => topic.toJson()).toList(),
    };
  }

  // Add JSON deserialization method
  factory Conf.fromJson(Map<String, dynamic> json) {
    return Conf(
      name: json['name'] as String,
      title: json['title']?.toString() ?? '',
      topics: (json['topics'] as List)
          .map((topicJson) => Topic.fromJson(topicJson))
          .toList(),
    );
  }
}
