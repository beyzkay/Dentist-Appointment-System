// lib/services/doctors_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tüm doktorları getirir (Map listesi halinde).
  Future<List<Map<String, dynamic>>> fetchAllDoctors() async {
    final snapshot = await _firestore.collection('doctors').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] as String? ?? 'İsimsiz Doktor',
        'specialization':
            data['specialization'] as String? ?? 'Genel Diş Hekimi',
        'imageUrl':
            data['imageUrl'] as String? ?? 'assets/doctor_placeholder.png',
        'availableDays': List<int>.from(data['availableDays'] ?? []),
        'weeklySchedule':
            Map<String, dynamic>.from(data['weeklySchedule'] ?? {}),
      };
    }).toList();
  }

  /// Tek bir doktoru getirir.
  Future<Map<String, dynamic>?> fetchDoctorById(String doctorId) async {
    final doc = await _firestore.collection('doctors').doc(doctorId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {
      'id': doc.id,
      'name': data['name'] as String? ?? 'İsimsiz Doktor',
      'specialization': data['specialization'] as String? ?? 'Genel Diş Hekimi',
      'imageUrl':
          data['imageUrl'] as String? ?? 'assets/doctor_placeholder.png',
      'availableDays': List<int>.from(data['availableDays'] ?? []),
      'weeklySchedule': Map<String, dynamic>.from(data['weeklySchedule'] ?? {}),
    };
  }
}
