import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:signin_signup_10/services/availability_service.dart';
import 'package:signin_signup_10/services/appointments_service.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  DateTime selectedDate = DateTime.now();
  final AppointmentScheduler scheduler = AppointmentScheduler();
  List<Doctor> doctors = [];
  bool isLoading = true;
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('doctors').get();
      final List<Doctor> loadedDoctors = [];

      for (var doc in snapshot.docs) {
        loadedDoctors.add(Doctor(
          id: doc.id,
          name: doc['name'] ?? 'İsimsiz Doktor',
          specialty: doc['specialization'] ?? 'Genel Diş Hekimi',
          imageUrl: 'assets/doctor_placeholder.png',
        ));
      }

      setState(() => doctors = loadedDoctors);
      _loadAppointmentsForSelectedDate();
    } catch (e) {
      debugPrint('Doktor yükleme hatası: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadAppointmentsForSelectedDate() async {
    if (doctors.isEmpty) return;

    setState(() => isLoading = true);

    try {
      for (var doctor in doctors) {
        final availability = await scheduler.getDoctorAvailability(
          doctorId: doctor.id,
          startDate: selectedDate,
          daysToCheck: 1,
        );

        final normalizedDate =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final availableSlots = availability[normalizedDate] ?? [];
        final userAppointments =
            await _getUserAppointments(doctor.id, normalizedDate);

        final updatedAppointments = <String, AppointmentStatus>{};

        for (int hour = 9; hour <= 17; hour++) {
          final timeSlot = '$hour:00';

          if (userAppointments.contains(hour)) {
            updatedAppointments[timeSlot] = AppointmentStatus.myBooking;
          } else if (availableSlots.contains(timeSlot)) {
            updatedAppointments[timeSlot] = AppointmentStatus.available;
          } else {
            updatedAppointments[timeSlot] = AppointmentStatus.booked;
          }
        }

        doctor.appointments = updatedAppointments;
      }
    } catch (e) {
      debugPrint('Randevu yükleme hatası: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<Set<int>> _getUserAppointments(String doctorId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: currentUserId)
          .where('appointmentTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs
          .map((doc) => (doc['appointmentTime'] as Timestamp).toDate().hour)
          .toSet();
    } catch (e) {
      debugPrint('Randevu sorgulama hatası: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Randevu Al',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A90E2)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Tarih seçici
                  _buildDateSelector(),

                  // Doktor listesi
                  Expanded(
                    child: _buildDoctorList(),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _buildLegend(),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 100,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Tarih Seçin',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 30,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedDate = date);
                    _loadAppointmentsForSelectedDate();
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A90E2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4A90E2)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date), // Kısa gün adı
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF718096),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    if (doctors.isEmpty) {
      return const Center(
        child: Text('Uygun doktor bulunamadı'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: doctors.length,
      itemBuilder: (context, index) => _buildDoctorCard(doctors[index]),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF4A90E2),
                  size: 40,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uygun Saatler',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doctor.appointments.entries.map((entry) {
                  final hour = entry.key;
                  final status = entry.value;

                  return GestureDetector(
                    onTap: status == AppointmentStatus.available
                        ? () => _bookAppointment(doctor, hour)
                        : status == AppointmentStatus.myBooking
                            ? () => _cancelAppointment(doctor, hour)
                            : null,
                    child: Container(
                      width: 70,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusBorderColor(status),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hour,
                          style: TextStyle(
                            color: _getStatusTextColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Müsait', Colors.white, const Color(0xFFE2E8F0)),
          _buildLegendItem('Dolu', Colors.red[100]!, Colors.red),
          _buildLegendItem('Randevum', Colors.green[100]!, Colors.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color? borderColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor ?? bgColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF718096),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.available:
        return Colors.white;
      case AppointmentStatus.booked:
        return Colors.red[100]!;
      case AppointmentStatus.myBooking:
        return Colors.green[100]!;
    }
  }

  Color _getStatusBorderColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.available:
        return const Color(0xFFE2E8F0);
      case AppointmentStatus.booked:
        return Colors.red;
      case AppointmentStatus.myBooking:
        return Colors.green;
    }
  }

  Color _getStatusTextColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.available:
        return const Color(0xFF2D3748);
      case AppointmentStatus.booked:
        return Colors.red;
      case AppointmentStatus.myBooking:
        return Colors.green;
    }
  }

  void _bookAppointment(Doctor doctor, String hour) async {
    final hourInt = int.parse(hour.split(':')[0]);
    final TextEditingController complaintController = TextEditingController();
    final appointmentService = AppointmentsService();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevu Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: complaintController,
              decoration: const InputDecoration(
                labelText: 'Şikayetiniz',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (complaintController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen şikayetinizi giriniz.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await appointmentService.bookAppointment(
                  appointmentId: currentUserId!,
                  doctorId: doctor.id,
                  patientId: currentUserId!,
                  appointmentTime: DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    hourInt,
                  ),
                  notes: complaintController.text,
                  status: "booked",
                );

                if (mounted) {
                  setState(() {
                    doctor.appointments[hour] = AppointmentStatus.myBooking;
                  });
                }
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Randevu başarıyla alındı!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(Doctor doctor, String hour) async {
    final hourInt = int.parse(hour.split(':')[0]);
    final appointmentService = AppointmentsService();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevu İptali'),
        content:
            const Text('Bu randevuyu iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await appointmentService.cancelAppointment(
        currentUserId!,
      );

      if (mounted) {
        setState(() {
          doctor.appointments[hour] = AppointmentStatus.available;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Randevu başarıyla iptal edildi'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  Map<String, AppointmentStatus> appointments;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    Map<String, AppointmentStatus>? appointments,
  }) : appointments = appointments ?? {};
}

enum AppointmentStatus {
  available,
  booked,
  myBooking,
}
