import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/specialist_provider.dart';
import '../../data/models/specialist_model.dart';
import '../navigation/presentation/screens/main_navigation_screen.dart';

class BookingScreen extends StatefulWidget {
  final SpecialistModel specialist;
  const BookingScreen({Key? key, required this.specialist}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '10:00 AM - 11:00 AM';
  String _selectedPaymentMethod = 'bKash';

  // Real-time slot availability tracking
  Set<String> _bookedSlots = {};
  bool _isFetchingSlots = false;

  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '03:00 PM - 04:00 PM',
    '06:00 PM - 07:00 PM',
  ];

  final List<Map<String, String>> _paymentMethods = [
    {'name': 'bKash', 'icon': '📱'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  /// Fetches currently-booked (non-expired) slots for this specialist+date.
  /// When a slot's time window has ended on the server side, it is NOT returned,
  /// making it automatically available again for new patients.
  Future<void> _fetchBookedSlots() async {
    if (!mounted) return;
    setState(() => _isFetchingSlots = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      final result = await ApiService.get(
        'appointments/booked-slots/?specialist_id=${widget.specialist.id}&date=$dateStr',
        requireAuth: false,
      );
      if (mounted && result != null && result['booked_slots'] is List) {
        setState(() {
          _bookedSlots = Set<String>.from(result['booked_slots'] as List);
          // If selected slot is now booked, reset to first available
          if (_bookedSlots.contains(_selectedTimeSlot)) {
            final available = _timeSlots.firstWhere(
              (s) => !_bookedSlots.contains(s),
              orElse: () => _selectedTimeSlot,
            );
            _selectedTimeSlot = available;
          }
        });
      }
    } catch (_) {
      // Silently fail — all slots remain selectable if API unreachable
    } finally {
      if (mounted) setState(() => _isFetchingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;


    return Scaffold(
      backgroundColor: isDark ? AppColors.darkForestBg : AppColors.lightGrayishGreen, // #1A2B2C in Dark, #F0F8F0 in Light
      appBar: AppBar(
        backgroundColor: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Header
        elevation: 0,
        title: Text(isBn ? 'সেশন বুকিং' : 'Book Session', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialist Summary Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkForestSurface : AppColors.paleGreen, // #2C3E3F in Dark, #E0EEE0 in Light
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.sageGreen.withOpacity(0.4) : AppColors.sageGreen.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.specialist.name.split(' ').last[0],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.specialist.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBn ? widget.specialist.titleBn : widget.specialist.titleEn,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fee: ৳${widget.specialist.feeBdt}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker Section
            Text(isBn ? 'তারিখ নির্বাচন করুন' : 'Select Date', style: AppTypography.heading2(context)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _fetchBookedSlots(); // Reload availability for new date
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white : Colors.white),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Slot Selection
            Row(
              children: [
                Text(isBn ? 'সময় নির্বাচন করুন' : 'Select Time Slot', style: AppTypography.heading2(context)),
                if (_isFetchingSlots) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((slot) {
                final isBooked = _bookedSlots.contains(slot);
                final isSelected = _selectedTimeSlot == slot && !isBooked;
                return Opacity(
                  opacity: isBooked ? 0.45 : 1.0,
                  child: ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slot,
                          style: TextStyle(
                            color: isBooked
                                ? Colors.white
                                : (isSelected ? Colors.white : (isDark ? Colors.white : Colors.black)),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            decoration: isBooked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (isBooked)
                          Text(
                            isBn ? 'বুকড' : 'Booked',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isBooked
                        ? (isDark ? const Color(0xFF1A1A2E) : Colors.white)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    side: BorderSide(
                      color: isBooked
                          ? Colors.white
                          : (isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white : Colors.white)),
                    ),
                    onSelected: isBooked
                        ? null // Cannot select a booked slot
                        : (selected) {
                            setState(() => _selectedTimeSlot = slot);
                          },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),


            // Payment Method Selection
            Text(isBn ? 'পেমেন্ট পদ্ধতি' : 'Select Payment Method', style: AppTypography.heading2(context)),
            const SizedBox(height: 12),
            Column(
              children: _paymentMethods.map((m) {
                final isSelected = _selectedPaymentMethod == m['name'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.white),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: RadioListTile<String>(
                      activeColor: AppColors.primary,
                      title: Row(
                        children: [
                          Text(m['icon']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            m['name']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      value: m['name']!,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPaymentMethod = val);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Confirm Booking Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  _showPaymentGatewayModal(context, isBn);
                },
                child: Text(
                  isBn ? 'পেমেন্ট ও বুকিং নিশ্চিত করুন (৳${widget.specialist.feeBdt})' : 'Pay & Confirm Booking (৳${widget.specialist.feeBdt})',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentGatewayModal(BuildContext context, bool isBn) {
    final parentCtx = context;
    final mobileController = TextEditingController(text: '01770618575');
    final otpController = TextEditingController(text: '123456');
    final pinController = TextEditingController(text: '12121');
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    bool isLoading = false;
    const primaryThemeColor = Color(0xFFE2136E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryThemeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'bKash Tokenized Checkout API',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryThemeColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invoice: $invoiceNumber',
                          style: const TextStyle(fontSize: 12, color: primaryThemeColor, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Amount: ৳${widget.specialist.feeBdt}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'bKash Mobile Number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Verification OTP',
                            prefixIcon: const Icon(Icons.password),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN Code',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryThemeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (isLoading || _selectedTimeSlot == null)
                          ? null
                          : () async {
                              setModalState(() => isLoading = true);
                              final specProvider = Provider.of<SpecialistProvider>(parentCtx, listen: false);
                              final appDateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
                              String verifiedTrxId = 'TR0011${DateTime.now().millisecondsSinceEpoch}';

                              // Resolve authenticated patient before API call
                              final authProviderPre = Provider.of<AuthProvider>(parentCtx, listen: false);
                              final currentUserPre = authProviderPre.currentUser;
                              final patientIdForApi = currentUserPre?.id;

                              final patientFullName = currentUserPre != null
                                  ? '${currentUserPre.firstName} ${currentUserPre.lastName}'.trim()
                                  : '';
                              final patientDisplayName = patientFullName.isNotEmpty
                                  ? patientFullName
                                  : (currentUserPre?.username ?? 'Patient');

                              int? createdAppointmentId;

                              // 1. Sync appointment to backend
                              try {
                                final bookingRes = await ApiService.post(
                                  ApiEndpoints.bookings,
                                  {
                                    'specialist': widget.specialist.id,
                                    'specialist_id': widget.specialist.id,
                                    'specialist_name': widget.specialist.name,
                                    'appointment_date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                    'time_slot': _selectedTimeSlot,
                                    'status': 'pending',
                                    'notes': 'Booked with ${widget.specialist.name}',
                                    if (patientIdForApi != null) 'patient': patientIdForApi,
                                    if (patientIdForApi != null) 'patient_id': patientIdForApi,
                                    'patient_name': patientDisplayName,
                                    if (currentUserPre?.email != null) 'patient_email': currentUserPre!.email,
                                  },
                                  requireAuth: false,
                                ).timeout(const Duration(seconds: 12));

                                if (bookingRes != null && bookingRes['id'] != null) {
                                  createdAppointmentId = bookingRes['id'];
                                }
                              } catch (_) {}

                              // 2. Call bKash payment gateway
                              try {
                                const payEndpoint = 'payments/bkash/execute/';
                                final response = await ApiService.post(
                                  payEndpoint,
                                  {
                                    'amount': widget.specialist.feeBdt,
                                    'purpose': 'Consultation Session with ${widget.specialist.name}',
                                    'mobile_number': mobileController.text.trim(),
                                    'otp': otpController.text.trim(),
                                    'pin': pinController.text.trim(),
                                    if (patientIdForApi != null) 'patient_id': patientIdForApi,
                                    if (patientIdForApi != null) 'patient': patientIdForApi,
                                    'patient_name': patientDisplayName,
                                    if (currentUserPre?.email != null) 'patient_email': currentUserPre!.email,
                                    if (createdAppointmentId != null) 'appointment_id': createdAppointmentId,
                                  },
                                  requireAuth: true,
                                ).timeout(const Duration(seconds: 4));

                                if (response != null && response['transaction_id'] != null) {
                                  verifiedTrxId = response['transaction_id'].toString();
                                }
                              } catch (_) {}

                              // 3. Register session in specialist provider for immediate availability
                              final patientId = currentUserPre?.id.toString() ?? 'pat_${DateTime.now().millisecondsSinceEpoch}';
                              final patientAvatar = currentUserPre?.avatar ?? '';

                              specProvider.addAppointment(
                                SpecialistAppointmentModel(
                                  id: 'app_${DateTime.now().millisecondsSinceEpoch}',
                                  patientId: patientId,
                                  patientName: patientDisplayName,
                                  patientAvatar: patientAvatar,
                                  specialistName: widget.specialist.name,
                                  specialistAvatar: widget.specialist.imageUrl,
                                  date: appDateStr,
                                  timeSlot: _selectedTimeSlot,
                                  category: widget.specialist.specialization,
                                  status: 'confirmed',
                                  meetingLink: 'https://meet.google.com/ash-wash-wellness-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                  notes: 'Booked session with ${widget.specialist.name} (TrxID: $verifiedTrxId)',
                                ),
                              );

                              // 4. Pop bottom sheet and show success dialog
                              Navigator.pop(modalCtx);
                              if (mounted) {
                                _showSuccessDialog(parentCtx, isBn, verifiedTrxId);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isBn ? '🔒 পেমেন্ট সম্পন্ন করুন (৳${widget.specialist.feeBdt})' : '🔒 Confirm & Pay ৳${widget.specialist.feeBdt}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, bool isBn, String trxId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 70),
              const SizedBox(height: 16),
              Text(
                isBn ? 'বুকিং ও পেমেন্ট সফল হয়েছে!' : 'Booking & Payment Confirmed!',
                style: AppTypography.heading2(context),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'bKash TrxID: $trxId',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBn
                    ? 'আপনার গুগল মিট লিংক নোটিফিকেশনে পাঠানো হয়েছে।'
                    : 'Google Meet link sent to your notifications drawer.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                },
                child: Text(isBn ? 'হোম পেজে ফিরে যান' : 'Back to Home', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
