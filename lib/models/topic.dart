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
    // Extract topic handle from first post handle
    String constructedHandle = '';
    String? firstPostHandle = json['posts']?[0]?['handle']?.toString();
    if (firstPostHandle != null) {
      // Split on dots and take first two parts (e.g. "news.3578" from "news.3578.1468")
      List<String> parts = firstPostHandle.split('.');
      if (parts.length >= 2) {
        constructedHandle = '${parts[0]}.${parts[1]}';
      }
    }

    final topic = Topic(
      conf: json['conf']?.toString() ?? '',
      handle: constructedHandle, // Using the constructed handle
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
