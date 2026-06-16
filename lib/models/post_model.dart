import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String userStatus;

  // Status: HILANG or DITEMUKAN
  final String statusKejadian;

  // Item category: KTM, Dompet, Helm, Tas, Buku, Lainnya
  final String jenisBarang;

  // Dynamic fields
  final String? nim;
  final String? namaPadaKtm;
  final String? warnaDominan;
  final String? namaIdentitas;
  final String? namaBarangLainnya;

  // Common fields
  final String namaBarang;
  final String deskripsi;
  final String lokasi;
  final Timestamp waktuKejadian;
  final String? fotoUrl;

  // Reward (only for HILANG)
  final int? rewardNominal; // 0 = no reward, -2 = secret, positive = amount
  final String? rewardLabel;

  // Duration
  final int durasiHari;
  final Timestamp expireAt;

  // Post status: AKTIF, SELESAI
  final String statusPost;

  final Timestamp createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.userStatus,
    required this.statusKejadian,
    required this.jenisBarang,
    this.nim,
    this.namaPadaKtm,
    this.warnaDominan,
    this.namaIdentitas,
    this.namaBarangLainnya,
    required this.namaBarang,
    required this.deskripsi,
    required this.lokasi,
    required this.waktuKejadian,
    this.fotoUrl,
    this.rewardNominal,
    this.rewardLabel,
    required this.durasiHari,
    required this.expireAt,
    required this.statusPost,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      userStatus: data['userStatus'] ?? '',
      statusKejadian: data['statusKejadian'] ?? 'HILANG',
      jenisBarang: data['jenisBarang'] ?? '',
      nim: data['nim'],
      namaPadaKtm: data['namaPadaKtm'],
      warnaDominan: data['warnaDominan'],
      namaIdentitas: data['namaIdentitas'],
      namaBarangLainnya: data['namaBarangLainnya'],
      namaBarang: data['namaBarang'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      lokasi: data['lokasi'] ?? '',
      waktuKejadian: data['waktuKejadian'] ?? Timestamp.now(),
      fotoUrl: data['fotoUrl'],
      rewardNominal: data['rewardNominal'],
      rewardLabel: data['rewardLabel'],
      durasiHari: data['durasiHari'] ?? 7,
      expireAt: data['expireAt'] ?? Timestamp.now(),
      statusPost: data['statusPost'] ?? 'AKTIF',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userStatus': userStatus,
      'statusKejadian': statusKejadian,
      'jenisBarang': jenisBarang,
      'nim': nim,
      'namaPadaKtm': namaPadaKtm,
      'warnaDominan': warnaDominan,
      'namaIdentitas': namaIdentitas,
      'namaBarangLainnya': namaBarangLainnya,
      'namaBarang': namaBarang,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'waktuKejadian': waktuKejadian,
      'fotoUrl': fotoUrl,
      'rewardNominal': rewardNominal,
      'rewardLabel': rewardLabel,
      'durasiHari': durasiHari,
      'expireAt': expireAt,
      'statusPost': statusPost,
      'createdAt': createdAt,
    };
  }
}
