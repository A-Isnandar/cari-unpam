import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String namaLengkap;
  final String nomorWa;
  final String status;
  final String? photoUrl;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.namaLengkap,
    required this.nomorWa,
    required this.status,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      namaLengkap: data['namaLengkap'] ?? '',
      nomorWa: data['nomorWa'] ?? '',
      status: data['status'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'namaLengkap': namaLengkap,
      'nomorWa': nomorWa,
      'status': status,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }
}
