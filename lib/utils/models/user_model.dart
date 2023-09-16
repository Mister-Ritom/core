import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String name;
  String username;
  String email;
  DateTime? dob;
  String? gender;
  String? website;
  String? bio;
  String? photoUrl;
  String? bannerUrl;
  Timestamp timestamp; // Added timestamp

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.dob,
    this.gender,
    this.website,
    this.bio,
    this.photoUrl,
    this.bannerUrl,
    Timestamp? timestamp, // Added timestamp parameter
  }) : timestamp = timestamp ?? Timestamp.now(); // Set default value for timestamp

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      gender: json['gender'],
      website: json['website'],
      bio: json['bio'],
      photoUrl: json['photoUrl'],
      timestamp:json['timestamp'], // Deserialize timestamp
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'website': website,
      'bio': bio,
      'photoUrl': photoUrl,
      'timestamp': timestamp, // Serialize timestamp
    };
  }
}
