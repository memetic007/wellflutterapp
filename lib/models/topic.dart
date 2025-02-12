import 'post.dart';

class Topic {
  String conf;
  String handle;
  String title;
  List<Post> posts;

  Topic({
    required this.conf,
    required this.handle,
    required this.title,
    List<Post>? posts,
  }) : posts = posts ?? [];

  // Factory constructor for empty topic
  factory Topic.empty() {
    return Topic(
      conf: "",
      handle: "",
      title: "",
      posts: [],
    );
  }

  void addPost(Post post) {
    posts.add(post);
  }

  Map<String, dynamic> toJson() {
    return {
      'conf': conf,
      'handle': handle,
      'title': title,
      'posts': posts.map((post) => post.toJson()).toList(),
    };
  }
} 