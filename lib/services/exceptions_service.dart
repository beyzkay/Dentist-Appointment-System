import 'package:cloud_firestore/cloud_firestore.dart';

class ExceptionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Bir doktorun tüm istisnalarını getirir.
  Future<List<Map<String, dynamic>>> fetchExceptions(String doctorId) async {
    final snapshot = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('exceptions')
        .orderBy('startDate')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'startDate': data['startDate'] as Timestamp,
        'endDate': data['endDate'] as Timestamp,
        'isFullDay': data['isFullDay'] as bool,
        'blockedHours': List<String>.from(data['blockedHours'] ?? []),
        'notes': data['notes'] as String? ?? '',
        'type': data['type'] as String? ?? '',
      };
    }).toList();
  }

  /// Yeni istisna ekler.
  Future<void> addException(
      String doctorId, Map<String, dynamic> exception) async {
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('exceptions')
        .add({
      'startDate': exception['startDate'],
      'endDate': exception['endDate'],
      'isFullDay': exception['isFullDay'],
      'blockedHours': exception['blockedHours'] ?? [],
      'notes': exception['notes'] ?? '',
      'type': exception['type'] ?? '',
      'doctorId': doctorId,
    });
  }

  /// Var olan istisnayı günceller.
  Future<void> updateException(String doctorId, String exceptionId,
      Map<String, dynamic> exception) async {
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('exceptions')
        .doc(exceptionId)
        .update({
      'startDate': exception['startDate'],
      'endDate': exception['endDate'],
      'isFullDay': exception['isFullDay'],
      'blockedHours': exception['blockedHours'] ?? [],
      'notes': exception['notes'] ?? '',
      'type': exception['type'] ?? '',
    });
  }

  /// İstisna siler.
  Future<void> deleteException(String doctorId, String exceptionId) async {
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('exceptions')
        .doc(exceptionId)
        .delete();
  }
}
