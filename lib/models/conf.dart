import 'topic.dart';

class Conf {
  String name;
  String handle;
  String title;
  List<Topic> topics;

  Conf({
    required this.name,
    required this.handle,
    required this.title,
    List<Topic>? topics,
  }) : topics = topics ?? [];

  // Factory constructor for empty conference
  factory Conf.empty() {
    return Conf(
      name: "",
      handle: "",
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
      'handle': handle,
      'title': title,
      'topics': topics.map((topic) => topic.toJson()).toList(),
    };
  }
} 