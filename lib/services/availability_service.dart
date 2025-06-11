import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentScheduler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<DateTime, List<String>>> getDoctorAvailability({
    required String doctorId,
    required DateTime startDate,
    required int daysToCheck,
  }) async {
    final doctorDoc =
        await _firestore.collection('doctors').doc(doctorId).get();
    if (!doctorDoc.exists) {
      return {};
    }

    final weeklySchedule = doctorDoc['weeklySchedule'] as Map<String, dynamic>;
    final exceptions = await _getExceptions(doctorId);
    final holidays = await _getHolidays();

    final availabilityMap = <DateTime, List<String>>{};

    for (int i = 0; i < daysToCheck; i++) {
      final date = startDate.add(Duration(days: i));
      // Tarihi normalize et (saat, dakika, saniye, milisaniye sıfırlama)
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Bu tarih için başlangıçta boş liste oluştur
      availabilityMap[normalizedDate] = [];

      // 1. Tatil kontrolü (tüm doktorlar için)
      if (_isHoliday(normalizedDate, holidays)) {
        continue;
      }

      // 2. Haftalık programa göre çalışıyor mu?
      if (!_isWorkingDay(normalizedDate, weeklySchedule)) {
        continue;
      }

      // 3. Tam gün istisna kontrolü (doktor özel)
      if (_hasFullDayException(normalizedDate, exceptions)) {
        continue;
      }

      // 4. Uygun saat aralıklarını hesapla
      final availableSlots = await _getAvailableTimeSlots(
        date: normalizedDate,
        weeklySchedule: weeklySchedule,
        doctorId: doctorId,
        exceptions: exceptions,
      );

      availabilityMap[normalizedDate] = availableSlots;
    }

    return availabilityMap;
  }

  Future<List<Map<String, dynamic>>> _getExceptions(String doctorId) async {
    try {
      final query = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('exceptions')
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('İstisnalar alınırken hata: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getHolidays() async {
    try {
      final holidays = await _firestore.collection('holidays').get();
      return holidays.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Tatiller alınırken hata: $e');
      return [];
    }
  }

  bool _isHoliday(DateTime date, List<Map<String, dynamic>> holidays) {
    for (final holiday in holidays) {
      final start = (holiday['startDate'] as Timestamp).toDate();
      final end = (holiday['endDate'] as Timestamp).toDate();

      // Tatil aralığını kontrol et (tarih, tatil başlangıcı ve bitişi arasında mı)
      if (date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  bool _isWorkingDay(DateTime date, Map<String, dynamic> weeklySchedule) {
    final dayName = DateFormat('EEEE').format(date).toLowerCase();
    final workHours = weeklySchedule[dayName] as Map<String, dynamic>?;
    return workHours != null && workHours['start'] != null;
  }

  bool _hasFullDayException(
      DateTime date, List<Map<String, dynamic>> exceptions) {
    for (final exception in exceptions) {
      if (exception['isFullDay'] == true) {
        final start = (exception['startDate'] as Timestamp).toDate();
        final end = (exception['endDate'] as Timestamp).toDate();

        // İstisna aralığını kontrol et
        if (date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)))) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<String>> _getAvailableTimeSlots({
    required DateTime date,
    required Map<String, dynamic> weeklySchedule,
    required String doctorId,
    required List<Map<String, dynamic>> exceptions,
  }) async {
    final dayName = DateFormat('EEEE').format(date).toLowerCase();
    final workHours = weeklySchedule[dayName] as Map<String, dynamic>;

    if (workHours['start'] == null) return [];

    int startHour, endHour;
    try {
      startHour = int.parse(workHours['start']!.split(':')[0]);
      endHour = int.parse(workHours['end']!.split(':')[0]);
    } catch (e) {
      print('Saat ayrıştırma hatası: $e');
      return [];
    }

    final blockedHours = _getBlockedHours(date, exceptions);
    final bookedHours = await _getBookedHours(date, doctorId);

    final availableSlots = <String>[];
    for (int hour = startHour; hour < endHour; hour++) {
      if (!bookedHours.contains(hour) && !blockedHours.contains(hour)) {
        availableSlots.add('$hour:00');
      }
    }

    return availableSlots;
  }

  Set<int> _getBlockedHours(
      DateTime date, List<Map<String, dynamic>> exceptions) {
    final blockedHours = <int>{};

    for (final exception in exceptions) {
      if (exception['isFullDay'] == false) {
        final start = (exception['startDate'] as Timestamp).toDate();
        final end = (exception['endDate'] as Timestamp).toDate();

        if (date.year == start.year &&
            date.month == start.month &&
            date.day == start.day) {
          for (int hour = start.hour; hour < end.hour; hour++) {
            blockedHours.add(hour);
          }
        }
      }
    }

    return blockedHours;
  }

  Future<Set<int>> _getBookedHours(DateTime date, String doctorId) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final appointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return appointments.docs
          .map((doc) => (doc['appointmentTime'] as Timestamp).toDate().hour)
          .toSet();
    } catch (e) {
      print('Randevular alınırken hata: $e');
      return {};
    }
  }
}
