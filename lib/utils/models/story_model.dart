import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String uploaderId;
  final String? caption;
  final String? image; // Optional image
  final Timestamp timestamp; // Added timestamp

  Story({
    required this.id,
    required this.uploaderId,
    this.caption,
    this.image,
    Timestamp? timestamp, // Added timestamp parameter
  }) : timestamp = timestamp ?? Timestamp.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch); // Set default value for timestamp

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      uploaderId: json['uploaderId'],
      caption: json['caption'],
      image: json['image'],
      timestamp: json['timestamp'], // Deserialize timestamp
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uploaderId': uploaderId,
      'caption': caption,
      'image': image,
      'timestamp': timestamp, // Serialize timestamp
    };
  }
}
