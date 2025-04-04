import 'post.dart';
import '../utils/string_utils.dart';

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
    return Topic(
      conf: json['conf'] as String,
      handle: json['handle'] as String,
      title: (json['title'] as String).unescapeJson(),
      number: json['number'] as int? ?? 0,
      lastPost: json['lastPost'] as int? ?? 0,
      lastPostTime: json['lastPostTime'] as String? ?? '',
      lastPoster: json['lastPoster'] as String? ?? '',
      url: json['url'] as String? ?? '',
      posts: (json['posts'] as List<dynamic>?)
              ?.map((p) => Post.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
