import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://cariunpam-d19b7.appspot.com');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of active posts ordered by creation date
  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection('posts')
        .snapshots();
  }

  /// Stream of current user's posts
  Stream<QuerySnapshot> getMyPostsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  /// Upload image to ImgBB
  Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = await HttpClient().postUrl(uri);
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
      
      final body = 'key=d4f1cf96b33b452691d02094d3245cbf&image=${Uri.encodeComponent(base64Image)}';
      request.write(body);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final data = jsonResponse['data'];
        return data['display_url'] ?? data['url']; // Return the direct URL to the image
      } else {
        throw Exception('Gagal upload ke server ImgBB: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mengunggah gambar: $e');
    }
  }

  /// Create a new post
  Future<void> createPost(Map<String, dynamic> postData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user profile for name
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    final durasiHari = postData['durasiHari'] as int? ?? 7;
    final expireAt = Timestamp.fromDate(
      DateTime.now().add(Duration(days: durasiHari)),
    );

    await _firestore.collection('posts').add({
      ...postData,
      'userId': user.uid,
      'userName': userData?['namaLengkap'] ?? 'Anonim',
      'userPhotoUrl': user.photoURL ?? '',
      'expireAt': expireAt,
      'statusPost': 'AKTIF',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Smart Matching: check for matching items
    if (postData['nim'] != null && (postData['nim'] as String).isNotEmpty) {
      await _checkSmartMatch(
        nim: postData['nim'],
        statusKejadian: postData['statusKejadian'],
        currentUserId: user.uid,
      );
    }
  }

  /// Smart matching logic
  Future<void> _checkSmartMatch({
    required String nim,
    required String statusKejadian,
    required String currentUserId,
  }) async {
    // Look for opposite status with same NIM
    final oppositeStatus =
        statusKejadian == 'HILANG' ? 'DITEMUKAN' : 'HILANG';

    final matchingPosts = await _firestore
        .collection('posts')
        .where('nim', isEqualTo: nim)
        .where('statusKejadian', isEqualTo: oppositeStatus)
        .where('statusPost', isEqualTo: 'AKTIF')
        .get();

    for (final doc in matchingPosts.docs) {
      final data = doc.data();
      final targetUserId = data['userId'] as String;

      // Don't notify the same user
      if (targetUserId == currentUserId) continue;

      // Create notification document
      await _firestore.collection('notifications').add({
        'userId': targetUserId,
        'postId': doc.id,
        'message':
            'Ada yang ${oppositeStatus == "HILANG" ? "kehilangan" : "menemukan"} barang dengan ciri-ciri mirip milikmu! (NIM: $nim)',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Update post status (SELESAI)
  Future<void> updatePostStatus(String postId, String newStatus) async {
    await _firestore.collection('posts').doc(postId).update({
      'statusPost': newStatus,
    });
  }

  /// Delete a post and its verifications (Cascade Delete)
  Future<void> deletePost(String postId) async {
    final batch = _firestore.batch();
    
    // Delete post document
    final postRef = _firestore.collection('posts').doc(postId);
    batch.delete(postRef);

    // Get and delete all verifications inside this post
    final verificationsSnapshot = await postRef.collection('verifications').get();
    for (var doc in verificationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Add verification to a post
  Future<void> addVerification(String postId, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    await _firestore.collection('posts').doc(postId).collection('verifications').add({
      ...data,
      'userId': user.uid,
      'userName': userData?['namaLengkap'] ?? 'Anonim',
      'userPhotoUrl': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete verification
  Future<void> deleteVerification(String postId, String verificationId) async {
    await _firestore.collection('posts').doc(postId).collection('verifications').doc(verificationId).delete();
  }

  /// Get notifications for current user
  Stream<QuerySnapshot> getNotificationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({
      'read': true,
    });
  }
}
