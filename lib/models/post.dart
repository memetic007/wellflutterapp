class Post {
  String handle;
  String datetime;
  String datetime_iso8601;
  String username;
  String pseud;
  List<String> text;

  Post({
    required this.handle,
    required this.datetime,
    required this.username,
    required this.pseud,
    List<String>? text,
  })  : datetime_iso8601 = "",
        text = text ?? [];

  // Factory constructor for empty post
  factory Post.empty() {
    return Post(
      handle: "",
      datetime: "",
      username: "",
      pseud: "",
      text: [],
    );
  }

  void appendText(String newText) {
    text.add(newText);
  }

  Map<String, dynamic> toJson() {
    return {
      'handle': handle,
      'datetime': datetime,
      'datetime_iso8601': datetime_iso8601,
      'username': username,
      'pseud': pseud,
      'text': text,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final post = Post(
      handle: json['handle']?.toString() ?? '',
      datetime: json['datetime']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      pseud: json['pseud']?.toString() ?? '',
      text: (json['text'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
    post.datetime_iso8601 = json['datetime_iso8601']?.toString() ?? '';
    return post;
  }
}
