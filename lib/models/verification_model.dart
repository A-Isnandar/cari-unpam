import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String teks;
  final String fotoUrl;
  final Timestamp createdAt;

  VerificationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.teks,
    required this.fotoUrl,
    required this.createdAt,
  });

  factory VerificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      teks: data['teks'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'teks': teks,
      'fotoUrl': fotoUrl,
      'createdAt': createdAt,
    };
  }
}
