import 'post.dart';

class Topic {
  String conf;
  String handle;
  String title;
  List<Post> posts;
  int number;
  int lastPost;
  String lastPostTime;
  String lastPoster;
  String url;

  Topic({
    required this.conf,
    required this.handle,
    required this.title,
    List<Post>? posts,
    required this.number,
    required this.lastPost,
    required this.lastPostTime,
    required this.lastPoster,
    required this.url,
  }) : posts = posts ?? [];

  // Factory constructor for empty topic
  factory Topic.empty() {
    return Topic(
      conf: "",
      handle: "",
      title: "",
      posts: [],
      number: 0,
      lastPost: 0,
      lastPostTime: "",
      lastPoster: "",
      url: "",
    );
  }

  void addPost(Post post) {
    posts.add(post);
  }

  Map<String, dynamic> toJson() {
    return {
      'conf': conf,
      'handle': handle,
      'number': number,
      'title': title,
      'posts': posts.map((post) => post.toJson()).toList(),
      'lastPost': lastPost,
      'lastPostTime': lastPostTime,
      'lastPoster': lastPoster,
      'url': url,
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    // Use the conf field directly from JSON instead of parsing from handle
    String conf = json['conf']?.toString() ?? '';
    String handle = json['handle']?.toString() ?? '';

    // If conf is empty but we have a handle, try to extract conf from handle
    if (conf.isEmpty && handle.isNotEmpty) {
      final parts = handle.split('.');
      if (parts.length >= 2) {
        conf = parts[0];
      }
    }

    final topic = Topic(
      conf: conf,
      handle: handle,
      title: json['title']?.toString() ?? '',
      posts: (json['posts'] as List?)
              ?.map(
                  (postJson) => Post.fromJson(postJson as Map<String, dynamic>))
              .toList() ??
          [],
      number: json['number'] as int? ?? 0,
      lastPost: json['lastPost'] as int? ?? 0,
      lastPostTime: json['lastPostTime']?.toString() ?? '',
      lastPoster: json['lastPoster']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );

    return topic;
  }
}
