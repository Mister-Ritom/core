import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String uploaderId;
  final String caption;
  final String description;
  final String? image; // Optional image
  final Timestamp timestamp; // Added timestamp

  Post({
    required this.id,
    required this.uploaderId,
    required this.caption,
    required this.description,
    this.image,
    Timestamp? timestamp, // Added timestamp parameter
  }) : timestamp = timestamp ?? Timestamp.now(); // Set default value for timestamp

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      uploaderId: json['uploaderId'],
      caption: json['caption'],
      description: json['description'],
      image: json['image'],
      timestamp: json['timestamp'], // Deserialize timestamp
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uploaderId': uploaderId,
      'caption': caption,
      'searchCap': caption.toLowerCase(),
      'description': description,
      'image': image,
      'timestamp': timestamp, // Serialize timestamp
    };
  }

  //create a copywith method
  Post copyWith({
    String? id,
    String? uploaderId,
    String? caption,
    String? description,
    String? image,
    Timestamp? timestamp, // Added timestamp parameter
  }) {
    return Post(
      id: id ?? this.id,
      uploaderId: uploaderId ?? this.uploaderId,
      caption: caption ?? this.caption,
      description: description ?? this.description,
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp, // Updated timestamp
    );
  }
}
