import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/colors/app_colors.dart';
import '../application/appointment_providers.dart';
import '../domain/appointment.dart';
import '../domain/doctor.dart';

class TelemedicineScreen extends ConsumerStatefulWidget {
  const TelemedicineScreen({super.key});

  @override
  ConsumerState<TelemedicineScreen> createState() => _TelemedicineScreenState();
}

class _TelemedicineScreenState extends ConsumerState<TelemedicineScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  Doctor? _selectedDoctor;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTime = null; // reset time on date change
    });
  }

  void _bookAppointment() {
    if (_selectedDoctor == null || _selectedTime == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    ref.read(appointmentBookingProvider.notifier).bookAppointment(
          doctorId: _selectedDoctor!.id,
          date: dateStr,
          time: _selectedTime!,
          notes: _notesController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(availableDoctorsProvider);
    final isHighContrast = MediaQuery.highContrastOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isHighContrast
        ? (isDark ? AppColors.backgroundHighContrastDark : AppColors.backgroundHighContrastLight)
        : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);
        
    final textPrimary = isHighContrast
        ? (isDark ? AppColors.textPrimaryHighContrastDark : AppColors.textPrimaryHighContrastLight)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
        
    final bookingState = ref.watch(appointmentBookingProvider);

    // Listen to booking status
    ref.listen<AsyncValue<Appointment?>>(appointmentBookingProvider, (prev, next) {
      
      if (!next.isLoading && next.hasValue && next.value != null && (prev?.value == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        setState(() {
          _selectedTime = null;
          _selectedDoctor = null;
          _notesController.clear();
        });
      } else if (!next.isLoading && next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book: ${next.error.toString().replaceAll("Exception: ", "")}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Schedule Appointment', style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: doctorsAsync.when(
          data: (doctors) => _buildForm(context, doctors, isHighContrast, isDark, bookingState),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: textPrimary))),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Doctor> doctors, bool isHighContrast, bool isDark, AsyncValue bookingState) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slotsProvider = _selectedDoctor != null
        ? availableSlotsProvider(_selectedDoctor!.id, dateStr)
        : null;
    
    final slotsAsync = slotsProvider != null ? ref.watch(slotsProvider) : null;

    final primaryColor = isHighContrast ? AppColors.primaryHighContrast : AppColors.primary;
    final textPrimary = isHighContrast
        ? (isDark ? AppColors.textPrimaryHighContrastDark : AppColors.textPrimaryHighContrastLight)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Doctor Selection
          Text('Select Specialist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          DropdownButtonFormField<Doctor>(
            key: const Key('doctor_dropdown'),
            value: _selectedDoctor,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: surfaceColor,
            ),
            dropdownColor: surfaceColor,
            hint: Text('Choose a doctor', style: TextStyle(color: textPrimary)),
            items: doctors.map((doc) {
              return DropdownMenuItem(
                value: doc,
                child: Text('${doc.name} - ${doc.specialty}', style: TextStyle(color: textPrimary)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedDoctor = val;
                _selectedTime = null;
              });
            },
          ),
          const SizedBox(height: 32),

          // Date Selection
          Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                selectableDayPredicate: (day) {
                  return day.weekday < 6; // No weekends
                },
              );
              if (date != null) {
                _onDateChanged(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMMM d, yyyy').format(_selectedDate), style: TextStyle(color: textPrimary, fontSize: 16)),
                  Icon(Icons.calendar_today, color: primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Time Slots Selection
          Text('Available Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          if (_selectedDoctor == null)
            Text('Please select a doctor to see slots.', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))
          else if (slotsAsync != null)
            slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return Text('No slots available for this date.', style: TextStyle(color: textPrimary));
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: slots.map((time) {
                    final isSelected = _selectedTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTime = selected ? time : null;
                        });
                      },
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: surfaceColor,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading slots: $err', style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 32),

          // Notes
          Text('Notes (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any symptoms or topics to discuss?',
              hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: surfaceColor,
            ),
            style: TextStyle(color: textPrimary),
          ),
          const SizedBox(height: 48),

          // Submit Button
          ElevatedButton(
            onPressed: (_selectedDoctor != null && _selectedTime != null && !bookingState.isLoading)
                ? _bookAppointment
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: primaryColor.withOpacity(0.5),
            ),
            child: bookingState.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Confirm Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

