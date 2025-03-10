import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save call history to Firestore
  Future<void> saveCallHistory({
    required String phoneNumber,
    required String type,
    String? message,
    String? voiceNotePath,
    required DateTime timestamp,
    bool isFlagged = false,
  }) async {
    await _firestore.collection('callHistory').add({
      'phoneNumber': phoneNumber,
      'type': type,
      'message': message,
      'voiceNotePath': voiceNotePath,
      'timestamp': timestamp,
      'isFlagged': isFlagged,
    });
  }

  // Fetch call history from Firestore
  Stream<QuerySnapshot> getCallHistory() {
    return _firestore
        .collection('callHistory')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update flagged status in Firestore
  Future<void> updateFlaggedStatus(String docId, bool isFlagged) async {
    await _firestore.collection('callHistory').doc(docId).update({
      'isFlagged': isFlagged,
    });
  }
}
