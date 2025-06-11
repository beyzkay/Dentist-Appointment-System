import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<void> addDoctorsWithAuth() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final weeklySchedule = {
    'monday': {'start': '09:00', 'end': '17:00'},
    'tuesday': {'start': '09:00', 'end': '17:00'},
    'wednesday': {'start': '09:00', 'end': '17:00'},
    'thursday': {'start': '09:00', 'end': '17:00'},
    'friday': {'start': '09:00', 'end': '17:00'},
    'saturday': {'start': null, 'end': null},
    'sunday': {'start': null, 'end': null},
  };

  final doctors = [
    {
      'email': 'dr.lale@hospital.com',
      'password': 'lale123',
      'clinicAddress': "Nisantasi, Sisli, Istanbul",
      'name': "Dr. Lale Demir",
      'phone': "+902121234567",
      'specialization': "Genel Diş",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 6, 15)),
          'endDate': Timestamp.fromDate(DateTime(2025, 6, 20)),
          'isFullDay': true,
          'notes': "Yıllık izin",
          'type': "vacation",
        }
      ]
    },
    {
      'email': 'dr.mehmet@hospital.com',
      'password': 'mehmet456',
      'clinicAddress': "Bostanli, Karsiyaka, Izmir",
      'name': "Dr. Mehmet Kaya",
      'phone': "+902322343434",
      'specialization': "Orthodontist",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 8, 10)),
          'endDate': Timestamp.fromDate(DateTime(2025, 8, 15)),
          'isFullDay': true,
          'notes': "Konferans seyahati",
          'type': "businessTrip",
        },
      ]
    },
    {
      'email': 'dr.ali@hospital.com',
      'password': 'ali789',
      'clinicAddress': "Kızılay, Çankaya, Ankara",
      'name': "Dr. Ali Demir",
      'phone': "+903122345678",
      'specialization': "Orthopedics",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 7, 10, 9, 0)),
          'endDate': Timestamp.fromDate(DateTime(2025, 7, 10, 13, 0)),
          'isFullDay': false,
          'notes': "Diş hekimi randevusu",
          'type': "sick",
        },
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 8, 5)),
          'endDate': Timestamp.fromDate(DateTime(2025, 8, 7)),
          'isFullDay': true,
          'notes': "Konferans seyahati",
          'type': "businessTrip",
        },
      ]
    },
    {
      'email': 'dr.zeynep@hospital.com',
      'password': 'zeynep101',
      'clinicAddress': "Fenerbahce, Kadikoy, Istanbul",
      'name': "Dr. Zeynep Ak",
      'phone': "+902165432100",
      'specialization': "Pediatrics",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 8, 5)),
          'endDate': Timestamp.fromDate(DateTime(2025, 8, 7)),
          'isFullDay': true,
          'notes': "Konferans seyahati",
          'type': "businessTrip",
        },
      ]
    },
    {
      'email': 'dr.cem@hospital.com',
      'password': 'cem2024',
      'clinicAddress': "Alsancak, Konak, Izmir",
      'name': "Dr. Cem Yıldız",
      'phone': "+902322244444",
      'specialization': "Neurology",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 8, 15)),
          'endDate': Timestamp.fromDate(DateTime(2025, 8, 15)),
          'isFullDay': false,
          'notes': "Online eğitim (yarım gün)",
          'type': "training",
        },
      ]
    },
    {
      'email': 'dr.fatma@hospital.com',
      'password': 'fatma!123',
      'clinicAddress': "Atakent, Halkali, Istanbul",
      'name': "Dr. Fatma Şahin",
      'phone': "+902128888888",
      'specialization': "Ophthalmology",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 9, 1)),
          'endDate': Timestamp.fromDate(DateTime(2025, 9, 5)),
          'isFullDay': true,
          'notes': "Ücretsiz izin",
          'type': "unpaidLeave",
        },
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 9, 12, 10, 0)),
          'endDate': Timestamp.fromDate(DateTime(2025, 9, 12, 18, 0)),
          'isFullDay': false,
          'notes': "Evden çalışma",
          'type': "remoteWork",
        },
      ]
    },
    {
      'email': 'dr.burak@hospital.com',
      'password': 'burak_pass',
      'clinicAddress': "Cukurambar, Ankara",
      'name': "Dr. Burak Koc",
      'phone': "+903126666666",
      'specialization': "Dentistry",
      'birthDate': _generateRandomBirthDate(random),
      'identifierNumber': _generateRandomTCKN(),
      'weeklySchedule': weeklySchedule,
      'exceptions': [
        {
          'startDate': Timestamp.fromDate(DateTime(2025, 9, 12, 10, 0)),
          'endDate': Timestamp.fromDate(DateTime(2025, 9, 12, 18, 0)),
          'isFullDay': false,
          'notes': "Evden çalışma",
          'type': "remoteWork",
        },
      ]
    }
  ];

  for (var doctor in doctors) {
    try {
      // 1. Auth'da doktor hesabı oluştur
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: doctor['email'] as String,
        password: doctor['password'] as String,
      );

      String uid = userCredential.user!.uid;

      // 2. Firestore'a doktor verilerini ekle (doctors koleksiyonu)
      await firestore.collection('doctors').doc(uid).set({
        'clinicAddress': doctor['clinicAddress'],
        'name': doctor['name'],
        'phone': doctor['phone'],
        'specialization': doctor['specialization'],
        'uid': uid,
        'weeklySchedule': doctor['weeklySchedule'],
      });

      // 3. Exceptions'ları ayrı subcollection'a ekle
      final exceptionsRef = firestore
          .collection('doctors')
          .doc(uid)
          .collection('exceptions')
          .doc(uid);

      for (var exception
          in doctor['exceptions'] as List<Map<String, dynamic>>) {
        // Her exception için yeni doküman oluştur (otomatik ID)
        if (exception.isEmpty) continue;
        await exceptionsRef.set({
          'doctorId': uid, // Doktor UID referansı
          'startDate': exception['startDate'],
          'endDate': exception['endDate'],
          'isFullDay': exception['isFullDay'] ?? false,
          'notes': exception['notes'] as String? ?? '',
          'type': exception['type'] as String? ?? 'unknown',
        });
      }

      // 4. Users koleksiyonuna doktor bilgilerini ekle
      await firestore.collection('users').doc(uid).set({
        'birthDate': Timestamp.fromDate(doctor['birthDate'] as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'email': doctor['email'],
        'identifierNumber': doctor['identifierNumber'],
        'name': doctor['name'],
        'password': uid, // Auth UID'sini password olarak kullanıyoruz
        'phone': doctor['phone'],
        'role': 'doctor',
        'uid': uid,
      });

      print('✅ Doktor eklendi: ${doctor['email']}');
    } catch (e) {
      print('❌ Hata: ${doctor['email']} - ${e.toString()}');
    }
  }
}

// Yardımcı fonksiyon: Rastgele TC kimlik no üretir
String _generateRandomTCKN() {
  final random = Random();
  final first9 = List.generate(9, (_) => random.nextInt(10)).join();
  final tenth = ((int.parse(first9[0]) +
                  int.parse(first9[2]) +
                  int.parse(first9[4]) +
                  int.parse(first9[6]) +
                  int.parse(first9[8])) *
              7 -
          (int.parse(first9[1]) +
              int.parse(first9[3]) +
              int.parse(first9[5]) +
              int.parse(first9[7]))) %
      10;
  final eleventh =
      (List.generate(10, (i) => int.parse(i < 9 ? first9[i] : tenth.toString()))
              .reduce((a, b) => a + b)) %
          10;

  return '$first9$tenth$eleventh';
}

// Yardımcı fonksiyon: Rastgele doğum tarihi üretir (25-65 yaş arası)
DateTime _generateRandomBirthDate(Random random) {
  final currentYear = DateTime.now().year;
  final birthYear = currentYear - 25 - random.nextInt(40); // 25-65 yaş arası
  final birthMonth = 1 + random.nextInt(12);
  final birthDay = 1 + random.nextInt(28); // Tüm aylar için güvenli

  return DateTime(birthYear, birthMonth, birthDay);
}
