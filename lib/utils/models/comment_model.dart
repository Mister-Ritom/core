import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String userId;
  String content;
  Timestamp timestamp;

  Comment({
    required this.userId,
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      userId: json['userId'],
      content: json['content'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
